# DFM

A template project for solving Lana Labs test task.

# Implementation details
 - Application doesn't perssist any data so everything is handled in memory
 - I am not sure if it would be a real use case example but during my implementation I assumed that an event can only trigger one event.
 - I added `start_time` and `finish_time` for traces. `start_time` is set as `start_time` of first event in event list and `finish_time` is the latest DateTime stamp among `end_times` of all events.
- Filter function is implemented according to `star_time` and `end_time` of a trace. If trace is filtered if 
    - beginning time is earlier than start of time range
    - finish time is later than end of time range. 


# How to Run the Application

To install dependencies and start to application:

```
    mix deps.get
    iex -S mix
```

To run the tests: 
```
    mix test
```


Once application started you can either specify and input file or run it with given example input file. If  no argument is given to `DFM.build_traces()` function, it will use given input file by default. 

```
    traces_list = DFM.build_traces()    # returns list of traces with ordered events
    DFM.build_matrix(trace_list)        # builds direct follower matrix
    DFM.filter_results(trace_list, range_start, range_end)   # filters traces between given time range and builds matrix 
    
```