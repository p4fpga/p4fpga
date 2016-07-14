# Build P4FPGA from Source

First, checkout this repository
```
git clone https://github.com/hanw/p4fpga.git
```


Checkout P4FPGA depedencies
```
git submodule init
git submodule update
```

The compiler requires pyaml package
```
sudo pip install pyaml
```

Install p4c_bm
```
cd 
sudo python p4fpga/submodules/p4c_bm/setup.py install
```
