-- HADR -- Primary and secudary server
SELECT sys.dm_hadr_name_id_map.ag_name
,      sys.dm_hadr_availability_replica_cluster_states.replica_server_name
,      sys.dm_hadr_availability_replica_states.is_local
,      sys.dm_hadr_availability_replica_states.role_desc
,      sys.dm_hadr_availability_replica_states.operational_state_desc
,      sys.dm_hadr_availability_replica_states.connected_state_desc
,      sys.dm_hadr_availability_replica_states.recovery_health_desc
,      sys.dm_hadr_availability_replica_states.synchronization_health_desc
,      sys.dm_hadr_availability_replica_cluster_states.join_state_desc
FROM sys.dm_hadr_availability_replica_states INNER JOIN sys.dm_hadr_availability_replica_cluster_states
	ON	sys.dm_hadr_availability_replica_states.replica_id = sys.dm_hadr_availability_replica_cluster_states.replica_id INNER JOIN sys.dm_hadr_name_id_map
	ON	sys.dm_hadr_availability_replica_states.group_id = sys.dm_hadr_name_id_map.ag_id
  
