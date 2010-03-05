<!--
 ~ Licensed to the Apache Software Foundation (ASF) under one
 ~ or more contributor license agreements.  See the NOTICE file
 ~ distributed with this work for additional information
 ~ regarding copyright ownership.  The ASF licenses this file
 ~ to you under the Apache License, Version 2.0 (the
 ~ "License"); you may not use this file except in compliance
 ~ with the License.  You may obtain a copy of the License at
 ~
 ~    http://www.apache.org/licenses/LICENSE-2.0
 ~
 ~ Unless required by applicable law or agreed to in writing,
 ~ software distributed under the License is distributed on an
 ~ "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 ~ KIND, either express or implied.  See the License for the
 ~ specific language governing permissions and limitations
 ~ under the License.
-->
<Storage>
  <ClusterName>Cloud Benchmark</ClusterName>

  <AutoBootstrap>false</AutoBootstrap>

  <Keyspaces>
    <Keyspace Name="Keyspace1">
      <ColumnFamily CompareWith="BytesType" 
                    Name="Standard1" 
                    RowsCached="10%"
                    KeysCached="0"/>
      <ColumnFamily CompareWith="UTF8Type" Name="Standard2"/>
      <ColumnFamily CompareWith="TimeUUIDType" Name="StandardByUUID1"/>
      <ColumnFamily ColumnType="Super"
                    CompareWith="UTF8Type"
                    CompareSubcolumnsWith="UTF8Type"
                    Name="Super1"
                    RowsCached="1000"
                    KeysCached="50%"
                    Comment="A column family with supercolumns, whose column and subcolumn names are UTF8 strings"/>
      <ReplicaPlacementStrategy>org.apache.cassandra.locator.RackUnawareStrategy</ReplicaPlacementStrategy>

      <ReplicationFactor>${replication_factor}</ReplicationFactor>
      <EndPointSnitch>org.apache.cassandra.locator.EndPointSnitch</EndPointSnitch>
    </Keyspace>
  </Keyspaces>

  <Authenticator>org.apache.cassandra.auth.AllowAllAuthenticator</Authenticator>

  <Partitioner>org.apache.cassandra.dht.RandomPartitioner</Partitioner>
  <InitialToken></InitialToken>

  <CommitLogDirectory>/var/lib/cassandra/commitlog</CommitLogDirectory>
  <DataFileDirectories>
      <DataFileDirectory>/var/lib/cassandra/data</DataFileDirectory>
  </DataFileDirectories>
  <CalloutLocation>/var/lib/cassandra/callouts</CalloutLocation>
  <StagingFileDirectory>/var/lib/cassandra/staging</StagingFileDirectory>


  <Seeds>
    % for seed in peers:
      <Seed>${seed}</Seed>
    % endfor
  </Seeds>


  <!-- Miscellaneous -->

  <!-- Time to wait for a reply from other nodes before failing the command -->
  <RpcTimeoutInMillis>10000</RpcTimeoutInMillis>
  <!-- Size to allow commitlog to grow to before creating a new segment -->
  <CommitLogRotationThresholdInMB>128</CommitLogRotationThresholdInMB>


  <!-- Local hosts and ports -->

  <!-- 
   ~ Address to bind to and tell other nodes to connect to.  You _must_
   ~ change this if you want multiple nodes to be able to communicate!  
   ~
   ~ Leaving it blank leaves it up to InetAddress.getLocalHost(). This
   ~ will always do the Right Thing *if* the node is properly configured
   ~ (hostname, name resolution, etc), and the Right Thing is to use the
   ~ address associated with the hostname (it might not be).
  -->
  <ListenAddress>${interface}</ListenAddress>
  <!-- internal communications port -->
  <StoragePort>7000</StoragePort>

  <!--
   ~ The address to bind the RPC service to. Unlike ListenAddress above, you
   ~ *can* specify 0.0.0.0 here if you want to bind the RPC service to all
   ~ interfaces.
   ~
   ~ Leaving this blank has the same effect it does for ListenAddress,
   ~ (i.e. it will be based on the configured hostname of the node).
  -->
  <RPCAddress>${interface}</RPCAddress>
  <!-- RPC port (the port clients connect to). -->
  <RPCPort>9160</RPCPort>
  <!-- 
   ~ Whether or not to use a framed transport for Thrift. If this option
   ~ is set to true then you must also use a framed transport on the 
   ~ client-side, (framed and non-framed transports are not compatible).
  -->
  <ThriftFramedTransport>false</ThriftFramedTransport>


  <!--======================================================================-->
  <!-- Memory, Disk, and Performance                                        -->
  <!--======================================================================-->

  <!--
   ~ Access mode.  mmapped i/o is substantially faster, but only practical on
   ~ a 64bit machine (which notably does not include EC2 "small" instances)
   ~ or relatively small datasets.  "auto", the safe choice, will enable
   ~ mmapping on a 64bit JVM.  Other values are "mmap", "mmap_index_only"
   ~ (which may allow you to get part of the benefits of mmap on a 32bit
   ~ machine by mmapping only index files) and "standard".
   ~ (The buffer size settings that follow only apply to standard,
   ~ non-mmapped i/o.)
   -->
  <DiskAccessMode>auto</DiskAccessMode>

  <!--
   ~ Size of compacted row above which to log a warning.  (If compacted
   ~ rows do not fit in memory, Cassandra will crash.  This is explained
   ~ in http://wiki.apache.org/cassandra/CassandraLimitations and is
   ~ scheduled to be fixed in 0.7.)
  -->
  <RowWarningThresholdInMB>512</RowWarningThresholdInMB>

  <!--
   ~ Buffer size to use when performing contiguous column slices. Increase
   ~ this to the size of the column slices you typically perform. 
   ~ (Name-based queries are performed with a buffer size of 
   ~ ColumnIndexSizeInKB.)
  -->
  <SlicedBufferSizeInKB>64</SlicedBufferSizeInKB>

  <!--
   ~ Buffer size to use when flushing memtables to disk. (Only one 
   ~ memtable is ever flushed at a time.) Increase (decrease) the index
   ~ buffer size relative to the data buffer if you have few (many) 
   ~ columns per key.  Bigger is only better _if_ your memtables get large
   ~ enough to use the space. (Check in your data directory after your
   ~ app has been running long enough.) -->
  <FlushDataBufferSizeInMB>32</FlushDataBufferSizeInMB>
  <FlushIndexBufferSizeInMB>8</FlushIndexBufferSizeInMB>

  <!--
   ~ Add column indexes to a row after its contents reach this size.
   ~ Increase if your column values are large, or if you have a very large
   ~ number of columns.  The competing causes are, Cassandra has to
   ~ deserialize this much of the row to read a single column, so you want
   ~ it to be small - at least if you do many partial-row reads - but all
   ~ the index data is read for each access, so you don't want to generate
   ~ that wastefully either.
  -->
  <ColumnIndexSizeInKB>64</ColumnIndexSizeInKB>

  <!--
   ~ Flush memtable after this much data has been inserted, including
   ~ overwritten data.  There is one memtable per column family, and 
   ~ this threshold is based solely on the amount of data stored, not
   ~ actual heap memory usage (there is some overhead in indexing the
   ~ columns).
  -->
  <MemtableThroughputInMB>64</MemtableThroughputInMB>
  <!--
   ~ Throughput setting for Binary Memtables.  Typically these are
   ~ used for bulk load so you want them to be larger.
  -->
  <BinaryMemtableThroughputInMB>256</BinaryMemtableThroughputInMB>
  <!--
   ~ The maximum number of columns in millions to store in memory per
   ~ ColumnFamily before flushing to disk.  This is also a per-memtable
   ~ setting.  Use with MemtableThroughputInMB to tune memory usage.
  -->
  <MemtableOperationsInMillions>0.3</MemtableOperationsInMillions>
  <!--
   ~ The maximum time to leave a dirty memtable unflushed.
   ~ (While any affected columnfamilies have unflushed data from a
   ~ commit log segment, that segment cannot be deleted.)
   ~ This needs to be large enough that it won't cause a flush storm
   ~ of all your memtables flushing at once because none has hit
   ~ the size or count thresholds yet.  For production, a larger
   ~ value such as 1440 is recommended.
  -->
  <MemtableFlushAfterMinutes>60</MemtableFlushAfterMinutes>

  <!--
   ~ Unlike most systems, in Cassandra writes are faster than reads, so
   ~ you can afford more of those in parallel.  A good rule of thumb is 2
   ~ concurrent reads per processor core.  Increase ConcurrentWrites to
   ~ the number of clients writing at once if you enable CommitLogSync +
   ~ CommitLogSyncDelay. -->
  <ConcurrentReads>8</ConcurrentReads>
  <ConcurrentWrites>32</ConcurrentWrites>

  <!--
   ~ CommitLogSync may be either "periodic" or "batch."  When in batch
   ~ mode, Cassandra won't ack writes until the commit log has been
   ~ fsynced to disk.  It will wait up to CommitLogSyncBatchWindowInMS
   ~ milliseconds for other writes, before performing the sync.

   ~ This is less necessary in Cassandra than in traditional databases
   ~ since replication reduces the odds of losing data from a failure
   ~ after writing the log entry but before it actually reaches the disk.
   ~ So the other option is "timed," where writes may be acked immediately
   ~ and the CommitLog is simply synced every CommitLogSyncPeriodInMS
   ~ milliseconds.
  -->
  <CommitLogSync>periodic</CommitLogSync>
  <!--
   ~ Interval at which to perform syncs of the CommitLog in periodic mode.
   ~ Usually the default of 10000ms is fine; increase it if your i/o
   ~ load is such that syncs are taking excessively long times.
  -->
  <CommitLogSyncPeriodInMS>10000</CommitLogSyncPeriodInMS>
  <!--
   ~ Delay (in milliseconds) during which additional commit log entries
   ~ may be written before fsync in batch mode.  This will increase
   ~ latency slightly, but can vastly improve throughput where there are
   ~ many writers.  Set to zero to disable (each entry will be synced
   ~ individually).  Reasonable values range from a minimal 0.1 to 10 or
   ~ even more if throughput matters more than latency.
  -->
  <!-- <CommitLogSyncBatchWindowInMS>1</CommitLogSyncBatchWindowInMS> --> 

  <!--
   ~ Time to wait before garbage-collection deletion markers.  Set this to
   ~ a large enough value that you are confident that the deletion marker
   ~ will be propagated to all replicas by the time this many seconds has
   ~ elapsed, even in the face of hardware failures.  The default value is
   ~ ten days.
  -->
  <GCGraceSeconds>864000</GCGraceSeconds>
</Storage>
