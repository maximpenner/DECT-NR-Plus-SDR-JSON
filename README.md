# DECT NR+ Software Defined Radio JSON

The [DECT NR+ SDR](https://github.com/maximpenner/DECT-NR-Plus-SDR) can export JSON files containing information about received DECT NR+ packets. The code in this repository can be used to analyze these JSON files and plot different properties over time. This may also happen in real-time while the SDR is running. For this, a subset of the latest JSON files is read and analyzed continuously.

## How to run `main.m` while the SDR is running?

We assume the SDR is running and exporting JSON files. In parallel, we start Matlab and simply execute `main.m` after adjusting a few lines of code. The critical lines in `main.m` are:

```matlab
config_file_collection.folder_measurements = 'json_examples/';
%config_file_collection.folder_measurements = '../bin/';
config_file_collection.prefix = 'worker_pool_';
config_file_collection.n_end_ignore = 0;
config_file_collection.n_end_keep = 0;
config_file_collection.n_start_ignore = 0;
config_file_collection.n_start_keep = 0;
```

Firstly, the directory `config_file_collection.folder_measurements` must be set. The first option `'json_examples/'` can be used to test the code. The second option `'../bin/'` is a relative path to the directory of the SDR executable, which is also where the SDR saves JSON files. The value of `config_file_collection.prefix` defines the filename prefix. The prefix can be changed to include files of only one worker pool in case multiple worker pools export to the same directory.

Secondly, a subset of JSON files (minimum size is three) must be set with the following structure fields:

1. `n_end_ignore`: How many of the latest JSON files are ignored?
2. `n_end_keep`: How many of the latest JSON files are kept?
3. `n_start_ignore`: How many of the oldest JSON files are ignored?
4. `n_start_keep`: How many of the oldest JSON files are kept?

The following two examples assume the SDR has written 80 JSON files indexed from 0 to 79 thus far.

### Example 0

```matlab
config_file_collection.n_end_ignore = 5;
config_file_collection.n_end_keep = 20;
config_file_collection.n_start_ignore = 0;
config_file_collection.n_start_keep = 0;
```

1. Ignore the 5 latest files. Remaining subset is 0 to 74.
2. Keep the 20 latest files. Remaining subset is 55 to 74.
3. Ignore none of the oldest files. Remaining subset is 55 to 74.
4. Keep all of the oldest files. Remaining subset is 55 to 74.

So the files 55 to 74 will be processed. Afterwards, `main.m` waits for at least one additional JSON file to become available. If, for instance, during processing seven more JSON were created, the same process restarts for JSON files indexed from 0 to 79+7=86.

1. Ignore the 5 latest files. Remaining subset is 0 to 81.
2. Keep the 20 latest files. Remaining subset is 62 to 81.
3. Ignore none of the oldest files. Remaining subset is 62 to 81.
4. Keep all of the oldest files. Remaining subset is 62 to 81.

### Example 1

```matlab
config_file_collection.n_end_ignore = 5;
config_file_collection.n_end_keep = 20;
config_file_collection.n_start_ignore = 2;
config_file_collection.n_start_keep = 10;
```

1. Ignore the 5 latest files. Remaining subset is 0 to 74.
2. Keep the 20 latest files. Remaining subset is 55 to 74.
3. Ignore the 2 oldest files. Remaining subset is 57 to 74.
4. Keep the 10 oldest files. Remaining subset is 57 to 66.

So the files 57 to 66 will be processed. Afterwards, `main.m` waits for at least one additional JSON file to become available. If, for instance, during processing seven more JSON were created, the same process restarts for JSON files indexed from 0 to 79+7=86.

1. Ignore the 5 latest files. Remaining subset is 0 to 81.
2. Keep the 20 latest files. Remaining subset is 62 to 81.
3. Ignore the 2 oldest files. Remaining subset is 64 to 81.
4. Keep the 10 oldest files. Remaining subset is 64 to 73.

### Limiting subset size

The value `n_end_keep = 0` has a special function. It implies that **all** of the latest files should be part of the subset of JSON files. However, since the total number of JSON files is continuously growing if the SDR is running in parallel, so does the subset and thus the processing time. For that reason, setting `n_end_keep = 0` turns the realtime capability off and `main.m` analyzes the available JSON files only once and then stops.
