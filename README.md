[![Build Status](https://travis-ci.com/hanw/p4fpga.svg?token=QcAxzpNcQodXfewmHgNA&branch=master)](https://travis-ci.com/hanw/p4fpga)

# Build P4FPGA from Source

First, checkout this repository
```
git clone https://github.com/hanw/p4fpga.git
```


Checkout P4FPGA depedencies
```
cd {P4FPGA-DIR}
git submodule init
git submodule update
```

The compiler requires pyaml package
```
sudo pip install pyaml
```

Install p4c_bm
```
sudo python {P4FPGA-DIR}/submodules/p4c_bm/setup.py install
```
