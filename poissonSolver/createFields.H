volScalarField phi 
(
    IOobject 
    (
        "phi",
        runTime.timeName(),
        mesh,
        IOobject::NO_READ,
        IOobject::AUTO_WRITE
    ),
    mesh,
    dimensionedScalar("phi",dimensionSet(0,0,0,0,0,0,0),0.0)
);

dimensionedScalar k("k", dimensionSet(0, 2, -1, 0, 0, 0, 0), 1.0); // Example constant

volScalarField sourceTerm
(
    IOobject
    (
        "sourceTerm",
        runTime.timeName(),
        mesh,
        IOobject::MUST_READ,
        IOobject::AUTO_WRITE
    ),
    mesh
);