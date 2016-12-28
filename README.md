[![Build Status](https://travis-ci.com/hanw/p4fpga.svg?token=QcAxzpNcQodXfewmHgNA&branch=master)](https://travis-ci.com/hanw/p4fpga)

# Build P4FPGA from Source

You will need p4fpga and p4c repository
```
git clone https://github.com/hanw/p4fpga.git
git clone https://github.com/p4lang/p4c.git
```

Run bootstrap.sh in p4c
```
cd p4c
./bootstrap.sh
```

Create a soft-link to p4fpga source code in p4c
```
ln -s <path-to-p4fpga>/compiler extensions/c++ 
```

Build p4c with p4fpga backend
```
cd build
make -j8
```

