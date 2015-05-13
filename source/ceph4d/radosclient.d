module ceph4d.radosclient;
import ceph4d.radostypes;
import ceph4d.rados;
/**
*RadosClient
*author donglei xiaosan@outloo.com
*/
class RadosClient{
	
	private {
		string clusterName;
		rados_t cluster;
		string userName;
		uint64_t flags;
		int err;
		string configPath;

		rados_ioctx_t io;
		string poolName = "data";
	}
	///string clusterName, string userName
	this(string clusterName, string userName)
	{
		this.clusterName = clusterName;
		this.userName = userName;
	}

	this(string clusterName, string userName,string configPath)
	{
		this(clusterName, userName);
		this.configPath = configPath;
	}
	///连接
	void connect()
	{
		err = rados_create2(&cluster, cast(char*)clusterName,cast(char*)userName,flags);
		assert(err >= 0, "rados_create2 error");

		/* Read a Ceph configuration file to configure the cluster handle. */
		import std.file;
		if(!isFile(this.configPath))
		{
			assert( 0, "config file can not read:" ~ configPath);
		}
		err = rados_conf_read_file(cluster, cast(char*)configPath);
		assert(err >= 0, "cannot read config file:" ~ configPath);

		/* Connect to the cluster */
		err = rados_connect(cluster);
		assert(err >= 0, "ccannot connect to cluster: " ~clusterName);
	}
	~this()
	{
		this.close();
	}

	///创建io poolNmae
	void ioCtxCreate(string poolName)
	{
		this.poolName = poolName;

		err = rados_ioctx_create(cluster, cast(char*) poolName, &io);
		assert(err >= 0, "cannot open rados pool: " ~poolName);
	}


	///创建io poolNmae
	void write(string key, string value)
	{
		err = rados_write(io, cast(const char*)key, cast(const char*)value, value.length, 0);

		if (err < 0) 
		{
			assert(0, "write write error ");
		} 
	}
	///关闭
	void close()
	{
		if(io !is null)
			rados_ioctx_destroy(io);
		if(cluster !is null)
			rados_shutdown(cluster);
	}

	//
	void remove(string key)
	{
		err = rados_remove(io, cast( const(char*))key);

		if (err < 0) 
		{
			assert(0, "remove error ");
		} 
	}
	/**
	* Read data from an object
	* The io context determines the snapshot to read from, if any was set
	* by rados_ioctx_snap_set_read().
	* @param oid the name of the object to read from
	* @param buf where to store the results
	* @param len the number of bytes to read
	* @param off the offset to start reading from in the object
	* @returns number of bytes read on success, negative error code on
	* failure
	*/
	int read(string oid, char *buf, size_t len, uint64_t off)
	{
		
		return rados_read(io, cast(const char *)oid,buf,len,off);
	}

	/**
	* Get the value of an extended attribute on an object.
	* @param o name of the object
	* @param name which extended attribute to read
	* @param buf where to store the result
	* @param len size of buf in bytes
	* @returns length of xattr value on success, negative error code on failure
	*/
	int getXAttr(string oid, string attrName,size_t len = 50)
	{
		char[100] buf;
		auto error = rados_getxattr(io, cast(const char *)oid, cast(const char *)attrName, cast(char *)buf, len);
		if(error < 0)
		{
			throw new Exception("read xattr is error");
		}
		import std.stdio;
		writeln(buf);
		return error;
	}
	
	/**
	* Set an extended attribute on an object.
	* @param o name of the object
	* @param name which extended attribute to set
	* @param buf what to store in the xattr
	* @param len the number of bytes in buf
	* @returns 0 on success, negative error code on failure
	*/
	int setXAttr(string oid, string attrName, string buf)
	{
		return rados_setxattr( io, cast(const char *)oid ,cast(const char *) attrName, cast(const char *)buf, buf.length);
	}
	
	/**
	* Delete an extended attribute from an object.
	* @param io the context in which to delete the xattr
	* @param o the name of the object
	* @param name which xattr to delete
	* @returns 0 on success, negative error code on failure
	*/
	int rmXAttr(string oid, string attrName)
	{
		return rados_rmxattr( io, cast(const char *)oid ,cast(const char *) attrName);
	}

}

