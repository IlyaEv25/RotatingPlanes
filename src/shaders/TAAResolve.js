import vertex from "./Ortho.glslv"
import fragment from "./TAAResolve.glslf"

let TAAResolve = {
    vertexShader: vertex,
    fragmentShader: fragment,
    uniforms: {
        u_velocity: { type: "t", value: null },
        u_color: { type: "t", value: null },
        u_depth: { type: "t", value: null },
        u_accumulated_color: { type: "t", value: null },
        u_accumulated_depth: { type: "t", value: null },
        u_counter: { type: "f", value: null },
        resolution: { type: "v2", value: null }
    }
}

export default TAAResolve;