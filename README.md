# State synchronization mechanism

## Overview

This repository demos an approach to ensure multiple processes are always running using the same synchronization. The approach:

* Every process holds a copy of current and future configuration. 
* Every configuration has a start time which informs the process when the configuration becomes current configuration.
* At the time defined in the configuration all the processes switch to the new configuration. Any tasks starting at or after this time will be using new configuration.
* Every process must obtain the configuration information from configuration store. 
* Process is forbidden to perform any tasks unless it can verify it has the latest version of the configuration.
* System must define new configuration in advance to give enough time for processes to read it.

*Assumption:* processes synchronize using their clocks, so clock drift must be in an acceptable range.

Minimum time that should be reserved for propagation delay depends on the number of processes, caching strategies, acceptable 
load on the configuration store and stability of the network. Assuming 150 process running at the same time, AWS as the
cloud provider, Postgres as the configuration store, Redis as a cache and short lived process side caching I would start
by giving the system 1 minute for propagation delay and tune it further from there.

The code that deals with the synchronization mechanism resides in `app/services` directory. The entry point is
`app/services/handler/pong_handler.rb`.    

## Demo

In this demo I'll be using a fork of [example Karafka app](https://github.com/karafka/example-app). I'll trigger 
pong game included in the examples to create some work for my processes. Then I'll watch the logs to check
whether configuration change occurs at the scheduled time.

Copy required configs:
```
cp config/sidekiq.yml.example config/sidekiq.yml
cp config/redis.yml.example config/redis.yml
```

Create some processes, here in form of docker services:
```
docker-compose up -d --scale worker=10
```

Create initial configuration. Without configuration a process will raise `Errors::MissingConfigurationError`
```
docker-compose run server bundle exec rake configuration:default
```

Now, give the processes something to do:
```
docker-compose run server bundle exec rake waterdrop:send:ping COUNT=100
```

In this demo we want to observe the moment in which processes switch to a different config. We will start following
logs from worker processes in one terminal window:

```
docker-compose logs -f worker | grep '"include_mood"=>false'
```

Now, let's open a *new terminal*. We'll schedule a configuration update which will happen in 5 seconds. Paste these
command in the new terminal and see what happens in this and previous terminal.    

```
docker-compose run server bundle exec rake configuration:update
docker-compose logs -f worker | grep '"include_mood"=>true'
```

For reference here's an example output. First terminal - listening for logs before configuration change:

```
uki@hackingdeck: ~/projects/personal/state-synchronization (master*) 
$ docker-compose logs -f worker | grep '"include_mood"=>false'
worker_3     | I, [2020-08-07T10:42:45.247982 #6]  INFO -- : PongHandler using configuration: {"include_mood"=>false, "delay"=>0.01}
worker_7     | I, [2020-08-07T10:42:45.250964 #6]  INFO -- : PongHandler using configuration: {"include_mood"=>false, "delay"=>0.01}
worker_10    | I, [2020-08-07T10:42:45.254522 #6]  INFO -- : PongHandler using configuration: {"include_mood"=>false, "delay"=>0.01}
worker_9     | I, [2020-08-07T10:42:45.255894 #7]  INFO -- : PongHandler using configuration: {"include_mood"=>false, "delay"=>0.01}
worker_5     | I, [2020-08-07T10:42:45.261133 #7]  INFO -- : PongHandler using configuration: {"include_mood"=>false, "delay"=>0.01}
worker_2     | I, [2020-08-07T10:42:45.266941 #6]  INFO -- : PongHandler using configuration: {"include_mood"=>false, "delay"=>0.01}
worker_2     | I, [2020-08-07T10:42:45.270267 #6]  INFO -- : PongHandler using configuration: {"include_mood"=>false, "delay"=>0.01}
worker_7     | I, [2020-08-07T10:42:45.277537 #6]  INFO -- : PongHandler using configuration: {"include_mood"=>false, "delay"=>0.01}
worker_7     | I, [2020-08-07T10:42:45.279928 #6]  INFO -- : PongHandler using configuration: {"include_mood"=>false, "delay"=>0.01}
worker_9     | I, [2020-08-07T10:42:45.287988 #7]  INFO -- : PongHandler using configuration: {"include_mood"=>false, "delay"=>0.01}
worker_4     | I, [2020-08-07T10:42:45.288105 #7]  INFO -- : PongHandler using configuration: {"include_mood"=>false, "delay"=>0.01}
worker_4     | I, [2020-08-07T10:42:45.291114 #7]  INFO -- : PongHandler using configuration: {"include_mood"=>false, "delay"=>0.01}
worker_4     | I, [2020-08-07T10:42:45.292317 #7]  INFO -- : PongHandler using configuration: {"include_mood"=>false, "delay"=>0.01}
worker_8     | I, [2020-08-07T10:42:45.412696 #6]  INFO -- : PongHandler using configuration: {"include_mood"=>false, "delay"=>0.01}
worker_6     | I, [2020-08-07T10:42:45.535731 #6]  INFO -- : PongHandler using configuration: {"include_mood"=>false, "delay"=>0.01}
worker_8     | I, [2020-08-07T10:42:45.667574 #6]  INFO -- : PongHandler using configuration: {"include_mood"=>false, "delay"=>0.01}
```

Second terminal - listening for logs after configuration change: 

```
uki@hackingdeck: ~/projects/personal/state-synchronization (master*) 
$ docker-compose run server bundle exec rake configuration:update
Starting state-synchronization_zookeeper_1 ... done
Starting state-synchronization_redis_1     ... done
Starting state-synchronization_kafka_1     ... done
I, [2020-08-07T10:42:40.672774 #7]  INFO -- : Initializing Karafka server 7
I, [2020-08-07T10:42:40.691947 #7]  INFO -- : Config scheduled to take effect at: 2020-08-07 10:42:45.691 UTC

uki@hackingdeck: ~/projects/personal/state-synchronization (master*) 
$ docker-compose logs -f worker | grep '"include_mood"=>true'
worker_4     | I, [2020-08-07T10:42:45.768832 #7]  INFO -- : PongHandler using configuration: {"include_mood"=>true, "delay"=>5}
worker_5     | I, [2020-08-07T10:42:45.771512 #7]  INFO -- : PongHandler using configuration: {"include_mood"=>true, "delay"=>5}
worker_3     | I, [2020-08-07T10:42:45.771670 #6]  INFO -- : PongHandler using configuration: {"include_mood"=>true, "delay"=>5}
worker_8     | I, [2020-08-07T10:42:45.771872 #6]  INFO -- : PongHandler using configuration: {"include_mood"=>true, "delay"=>5}
```

I recommend using two terminals rather than analyzing logs post hoc. This is because logs may be written to file out of 
order and require sorting for easier understanding. 

## Things I'd like to change/try given more time

### Different Configuration store and caching 
I would use something else than Redis as the configuration store. :) I used Redis mostly because of ease of prototyping a 
solution. In production use I would start with something like Postgres and depending on performance take it further from 
there. Depending on the maximum time we can accept between setting new configuration and seeing it take effect I would 
define process side caching with appropriate TTL. To limit database calls even further I would then insert cache 
between the processes and Postgres. 

### Experiment with Zookeeper

According to [Apache ZooKeeper website](https://zookeeper.apache.org):

> ZooKeeper is a centralized service for maintaining configuration information, naming, providing distributed synchronization, and providing group services. 
My preferred approach would be to use push rather than pull to avoid unnecessary strain on the configuration store and 
also to ensure minimal delay between setting the configuration and propagating it through the system. Zookeeper seems
like a good candidate for this. Unfortunately, it looks like client libraries for Ruby are very old. 

Which sounds exactly like what I would need to ensure state synchronization between processes across a large system. 
One of my favorite features is the ability to use push rather than pull. Also, I'd like to use it as a coordinator
for two phase commit to ensure consistency.

Sadly, I have no experience with Zookeper and it looks like Zookeper libraries for Ruby are very old.

### Clock drift  

This solution relies on the processes using their clocks for synchronized configuration switch. Depending on the required
precision and the clock drift on the machines running the processes we may need to improve the drift. In such case
 [Amazon Time Sync service](https://aws.amazon.com/blogs/aws/keeping-time-with-amazon-time-sync-service/) looks promising. 

### Code quality 

Things related to code quality on the TODO list:
- Introduce `dry-rb` and use it especially for the configuration.
- Document the code. 
- Write integration tests.
- Do not pass `Karafka::Params:ParamsBatch` to `PongHandler`. Rather use the payload in a form that does not introduce 
dependency on Karafka.
- When processing a params batch, fetch the configuration before processing the batch, but check which configuration
should be used before processing each entry in the batch.
- Make it possible to pass arguments to `configuration:update` rake task.

### Fine tuning and performance testing

There's only so far testing on my local machine can take me. I'd like to deploy this solution to the cloud and see how
it behaves. 
- measure propagation time in the existing infrastructure
- check RDS metrics
- check Redis metrics (including replication time, if using a cluster)  

## References

* [Karafka example app](https://github.com/karafka/example-app)
* [Karafka framework](https://github.com/karafka/karafka)
* [Karafka example application Actions CI](https://github.com/karafka/example-app/actions?query=workflow%3Aci)
* [Karafka example application Coditsu](https://app.coditsu.io/karafka/repositories/example-app)
