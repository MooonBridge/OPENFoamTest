#include "fvMesh.H"
#include "fvSolution.H"
#include "volFields.H"
#include "Time.H"    

int main(int argc, char *argv[])
{
    #include "setRootCase.H"
    #include "createTime.H"
    #include "createMesh.H"
    #include "createFields.H"

    Foam::Time runTime(argc, argv, mesh);

    while (runTime.run())
    {
        #include "readTimeControls.H"
        #include "CourantNo.H"  

        fvScalarMatrix poissonEqn
        (
            -fvm::laplacian(k, phi) == sourceTerm
        );

        poissonEqn.solve();

        // Write results
        runTime.write();
    }

    return 0;
}