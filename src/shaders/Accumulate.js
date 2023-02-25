import vertex from "./Ortho.glslv"
import fragment from "./Accumulate.glslf"

let Accumulate = {
    vertexShader: vertex,
    fragmentShader: fragment,
    uniforms: {
        u_color: { type: "t", value: null },
        u_depth: { type: "t", value: null }
    }
}

export default Accumulate;