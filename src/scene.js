let Scene = { //extends three js scene
    deferedMaterials: [], //materials, each has a mesh array
    forwardMaterials: [],
    shadowMaterial : [], //meshes
    camera: null,
    lights: [

    ],
    invisible: []
}

let Material = {
    roughness: 0,
    metallic: 0,
    color: 0x0,
    emissiveColor: 0x0,
    emissiveStrength: 0
}

let light = {
    color: 0xffffff,
    intensity: 1.0,
    type: "AREA",
    attenuationRadius: 1.0,
    radius: 1.0,
    index: 0,
    shadowCamera: null,
}