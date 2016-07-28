
1. Enter into the external software dir
<br/><br/><pre><code>
cd ext/src
</code></pre>

2. Build gtest
<br/><br/><pre><code>cd gtest
CC=gcc CXX=g++  CXXFLAGS="-std=c++11" ./configure --prefix $(cd ../..; pwd)
make
mkdir ../../lib/
cp -fr include/gtest ../../include
cp lib/.libs/libgtest* ../../lib/
</code></pre>

3. Go back to the top level
<br/><br/><pre><code>cd ../..
</code></pre>
