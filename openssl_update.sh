wget https://www.openssl.org/source/openssl-1.1.1d.tar.gz
tar -zxvf openssl-1.1.1d.tar.gz
cd openssl-1.1.1d
./config --prefix=/usr/local/openssl
make
make install
mv /usr/bin/openssl /usr/bin/openssl.bak
ln -sf /usr/local/openssl/bin/openssl /usr/bin/openssl
echo "/usr/local/openssl/lib" >> /etc/ld.so.conf
ldconfig -v