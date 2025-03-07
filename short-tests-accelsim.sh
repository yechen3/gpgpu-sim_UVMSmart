if [ ! -n "$CUDA_INSTALL_PATH" ]; then
	echo "ERROR ** Install CUDA Toolkit and set CUDA_INSTALL_PATH.";
	exit 1;
fi

if [ ! -n "$ACCELSIM_BRANCH" ]; then
	echo "ERROR ** set the ACCELSIM_BRANCH env variable";
	exit 1;
fi

if [ ! -n "$GPUAPPS_ROOT" ]; then
	echo "ERROR ** GPUAPPS_ROOT to a location where the apps have been compiled";
	exit 1;
fi

git config --system --add safe.directory '*'

export PATH=$CUDA_INSTALL_PATH/bin:$PATH
source ./setup_environment
make -j

git clone https://github.com/accel-sim/accel-sim-framework.git

# Build accel-sim
cd accel-sim-framework
git checkout $ACCELSIM_BRANCH
source ./gpu-simulator/setup_environment.sh
make -j -C ./gpu-simulator

# Get rodinia traces
rm -rf ./hw_run/rodinia_2.0-ft
wget https://engineering.purdue.edu/tgrogers/accel-sim/traces/tesla-v100/latest/rodinia_2.0-ft.tgz
mkdir -p ./hw_run
tar -xzvf rodinia_2.0-ft.tgz -C ./hw_run
rm rodinia_2.0-ft.tgz

# Run rodinia traces
./util/job_launching/run_simulations.py -C QV100-SASS -B rodinia_2.0-ft -T ./hw_run/rodinia_2.0-ft/9.1 -N myTest
./util/job_launching/monitor_func_test.py -v -N myTest
