# climexp_data
The scripts to update the Climate Explorer data

These quick-and-dirty scripts pull data from >70 servers around the world and convert to standard formats for the local Climate Explorer data store. Some datasets are updated monthly, the scripts update_10.sh and update_25.sh are run around the 10th and 25th of each month (a week earlier nowadays) and in turn call the update scripts in the subdirectories.

Some old datasets have (gasp) Fortran code to extract time series from the format provided by the data provider, eg the GHCN and ECA&D collections of time series. Other have code that converts formats. I am working towards eliminating the Fortran or at least adding a 'make' into each of these update scripts.

There still are loads of local dependencies, such as calling my workstation 'zuidzee' for data that are too large for the 8-yr old staging server, or servers that do not accept the ancient openssl library it uses. Do not expect these scripts to run anywhere else without some effort. Feel free to try though.

Geert Jan van Oldenborgh
oldenborgh@knmi.nl
https://climexp.knmi.nl
