#!/bin/bash

# Variables
solver="incompressibleFluid"  # Solver to use
case_path="motorBike"  # Path to your OpenFOAM case
log_dir="benchmark_logs"  # Directory to store log files

# Create log directory
mkdir -p $log_dir

# Core configurations to test
core_counts=(2 4 6 8)

# Function to update decomposeParDict
update_decomposeParDict() {
    local cores=$1

    if [ "$cores" -eq 1 ]; then
        return  # No need to update decomposeParDict for single core
    fi

    # Initialize nx, ny, nz
    nx=1
    ny=1
    nz=1

    # Adjust decomposition for specific core counts
    case $cores in
        2)
            nx=2
            ny=1
            nz=1
            ;;
        4)
            nx=2
            ny=2
            nz=1
            ;;
        6)
            nx=3
            ny=2
            nz=1
            ;;
        8)
            nx=4
            ny=2
            nz=1
            ;;
        *)
            # For other values of cores, calculate a balanced decomposition
            # Starting values for the decomposition
            nx=$cores
            ny=1
            nz=1

            # Try to balance n along x, y, z by adjusting nx, ny, and nz
            while (( nx * ny * nz != cores )); do
                if (( nx * ny * nz < cores )); then
                    # If subdomains are less than cores, expand ny or nz
                    if (( ny <= nz )); then
                        ny=$(( ny * 2 ))  # Expand ny first (balance y-direction)
                    else
                        nz=$(( nz * 2 ))  # Expand nz if ny is already expanded
                    fi
                else
                    # If subdomains exceed cores, reduce nx
                    nx=$(( nx / 2 ))  # Shrink nx first (balance x-direction)
                fi

                # Check if we reached the desired decomposition
                if (( nx * ny * nz == cores )); then
                    break
                fi
            done
            ;;
    esac

    # Update the decomposeParDict with the calculated values for nx, ny, nz
    sed -i "s/^numberOfSubdomains.*/numberOfSubdomains $cores;/" $case_path/system/decomposeParDict
    sed -i "/hierarchicalCoeffs/,/}/c\\
hierarchicalCoeffs\\
{\\
    n               ($nx $ny $nz);\\
    order           xyz;\\
}" $case_path/system/decomposeParDict
}


# Benchmark loop
for cores in "${core_counts[@]}"
do
    echo "Running with $cores cores..."
    
    # Remove existing processor directories (if any)
    rm -rf $case_path/processor*

    if [ "$cores" -eq 1 ]; then
        # Single-core execution
        { time foamRun -solver $solver -case $case_path ; } 2> $log_dir/time_${cores}cores.txt
    else
        # Parallel execution
        update_decomposeParDict $cores
        decomposePar -case $case_path
        { time mpirun -np $cores foamRun -solver $solver -parallel -case $case_path ; } 2> $log_dir/time_${cores}cores.txt
    fi

    echo "Completed $cores cores run. Logs saved to $log_dir/time_${cores}cores.txt"
done

echo "Benchmarking complete. Check logs in $log_dir."
