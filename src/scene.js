let Scene = { //extends three js scene
    deferedObjects: [], //materials, each has a mesh array
    forwardObjects: [],
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
    position: THREE.Vector3(),
    color: THREE.Color(0xffffff),
    intensity: 1.0,
    type: "AREA",
    attenuationRadius: 1.0,
    radius: 1.0,
    index: 0,
    useShadow: false,
    shadowCamera: null,
}