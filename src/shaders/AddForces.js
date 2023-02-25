import fragment from "./AddForces.glslf";
import vertex from "./AddForces.glslv";
import { Vector2 } from "three";

let AddForces = {
  uniforms: {
    posWF: { type: "t", value: null },
    posWFPrev: { type: "t", value: null },
    posPrev: { type: "t", value: null },
    posPrevPrev: { type: "t", value: null },
    viewMat: { type: "m4", value: null },
    res: { type: "v2", value: new Vector2(256, 256) },
    attractor0: { type: "v3", value: null },
    pAttractor0: { type: "v3", value: null },
    attractor1: { type: "v3", value: null },
    pAttractor1: { type: "v3", value: null },
    attractor2: { type: "v3", value: null },
    pAttractor2: { type: "v3", value: null },
    decay: { type: "float", value: null },
    drag: { type: "float", value: 0 },
    time: { type: "f", value: null },
    globalScale: { type: "f", value: null },
  },
  vertexShader: vertex,
  fragmentShader: fragment,
};

export default AddForces;
