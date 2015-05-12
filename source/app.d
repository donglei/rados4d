import std.stdio;
import ceph4d.rados;
import std.conv:to;

void main()
{
	/* Declare the cluster handle and required arguments. */
	rados_t cluster;
	auto clusterName = "ceph";
	auto userName = "client.admin";
	uint64_t flags;

	/* Initialize the cluster handle with the "ceph" cluster name and the "client.admin" user */
	int err;
	err = rados_create2(&cluster, cast(char*)clusterName,cast(char*)userName,flags);
	assert(err >= 0, "rados_create2 error");

	/* Read a Ceph configuration file to configure the cluster handle. */
	auto configPath = "/etc/ceph/ceph.conf";
	err = rados_conf_read_file(cluster, cast(char*)configPath);
	writeln(err);
	assert(err >= 0, "cannot read config file:" ~ configPath);

	/* Connect to the cluster */
	err = rados_connect(cluster);
	assert(err >= 0, "ccannot connect to cluster: " ~clusterName);

	/*
	* Continued from previous C example, where cluster handle and
	* connection are established. First declare an I/O Context.
	*/

	rados_ioctx_t io;
	auto poolName = "data";

	err = rados_ioctx_create(cluster, cast(char*) poolName, &io);
	assert(err >= 0, "cannot open rados pool: " ~poolName);

	rados_write(io,"hw", "Hello World!", 12, 0);

	if (err < 0) 
	{
		rados_ioctx_destroy(io);
		rados_shutdown(cluster);
	} 
	
	auto xattr = "en_US";
	err = rados_setxattr(io, "hw", "lang", cast(const char*)xattr, 5);


}
