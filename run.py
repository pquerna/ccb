#!/usr/bin/python
# Licensed to Paul Querna under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# libcloud.org licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


HUDSON_ROOT = "http://hudson.zones.apache.org/hudson/job/Cassandra/"

JSON_API = HUDSON_ROOT + "lastSuccessfulBuild/api/json"
ARTIFACT_ROOT = HUDSON_ROOT + "lastSuccessfulBuild/artifact"

import cassconf
import paramiko
from mako.template import Template
from libcloud.types import Provider
from libcloud.providers import get_driver
from libcloud.deployment import SSHKeyDeployment

from os.path import join as pjoin
import urllib2
import tempfile
import shutil
try:
  import simplejson as json
except ImportError:
  import json

def log(str):
  print str

def get_hudson_data():
  data = urllib2.urlopen(JSON_API).read()
  hud = json.loads(data)
  return hud

# only tested on rackspace, should be trivial to port!
def get_libcloud_driver():
  return get_driver(Provider.RACKSPACE)(cassconf.USERNAME, cassconf.SECRET)

def artifact_buildnumber(hud):
  return hud["number"]

def artifact_url(hud):
  artifacts = [x["relativePath"] for x in hud["artifacts"]]
  tarurl = ARTIFACT_ROOT +"/"+ filter(lambda x: x.find("-bin") != -1, artifacts)[0]
  return tarurl

def get_artifact(tempdir, url):
  tarball = url[url.rfind("/")+1:]
  localpath = pjoin(tempdir, tarball)
  log("Downloading build from %s to %s" % (url, localpath))
  fp = open(localpath, 'w')
  fp.write(urllib2.urlopen(url).read())
  fp.close()
  return localpath

def boot_servers(driver, count, pubkey):
  loc = driver.list_locations()[0]
  size = filter(lambda x: x.ram == 256, driver.list_sizes(loc))[0]
  image = filter(lambda x: x.name.find("karmic") != -1, driver.list_images(loc))[0]
  nodes = []
  for i in range(count):
    log("booting machine %d with %s on %s size node" % (i, image.name, size.name))
    d = SSHKeyDeployment(pubkey)
    node = driver.deploy_node(name="cbench%d.querna.org" % (i),
                              location=loc, image=image, size=size, deploy=d)
    nodes.append(node)
  return nodes

def exec_wait(client, cmd):
  log("Running `%s`")
  stdin, stdout, stderr  = client.exec_command(cmd)
  stdin.close()
  return stdout.read(), stderr.read()

def storage_conf(server, peers):
  d = { "replication_factor": min(3, len(peers)+1),
        "peers": [s.private_ip[0] for s in peers],
        "interface": server.private_ip[0],
        }
  t = Template(filename='storage-conf.xml.mako')
  return t.render(**d)
  
def push_files(key, local, servers):
  tarball = local[local.rfind("/")+1:]
  for s in servers:
    conninfo = {'hostname': s.public_ip[0],
                'port': 22,
                'username': 'root',
                'pkey': key,
                'allow_agent': False,
                'look_for_keys': False}
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(**conninfo)
    try:
      sftp = client.open_sftp()
      sftp.put(local, tarball)
      print exec_wait(client, "tar -xvzf %s" % (tarball))
      dname = tarball[:tarball.rfind("-")]
      sftp.symlink(dname, "cassandra")
      conf = storage_conf(s, [x for x in servers if x != s])
      fp = sftp.open("cassandra/conf/storage-conf.xml", 'w')
      fp.write(conf)
      fp.close()
    finally:
      client.close()

def main():
  tempdir = tempfile.mkdtemp(prefix="cassandra-bench")
  try:
    hud = get_hudson_data()
    url = artifact_url(hud)
    buildnum = artifact_buildnumber(hud)
    data = urllib2.urlopen(JSON_API).read()
    local = get_artifact(tempdir, url)
    key = paramiko.RSAKey.generate(2048)
    key.write_private_key_file(pjoin(tempdir, "id_rsa"))
    pubkey = "ssh-rsa %s cassandrabench@paul.querna.org" % (key.get_base64())
    driver = get_libcloud_driver()
    servers = boot_servers(driver, cassconf.CLUSTER_SIZE, pubkey)
    push_files(key, local, servers)
    #
  finally:
    print "Cleaning up "+ tempdir
    #shutil.rmtree(tempdir)
    log("Cleaning up any booted servers....")
    driver = get_libcloud_driver()
    [n.destroy() for n in driver.list_nodes() if n.name.find('cbench') != -1]

if __name__ == "__main__":
  main()
