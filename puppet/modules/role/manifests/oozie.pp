# == Class role::oozie
# Install Oozie server and client.
#
class role::oozie {
    require ::mysql
    require ::role::hadoop
    class { '::cdh::oozie': }
    class { '::cdh::oozie::server':
        db_root_password => $::mysql::root_password,
    }

    # Make sure HDFS is totally ready before the CDH
    # module tries to create this directory.
    Exec['wait_for_hdfs'] -> Cdh::Hadoop::Directory['/user/oozie']
}
