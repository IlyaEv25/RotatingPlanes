import vertex from "./Ortho.glslv"
import fragment from "./Final.glslf"

let Final = {
    vertexShader: vertex,
    fragmentShader: fragment,
    uniforms: {
        u_color: { type: "t", value: null },
        toneMappingExposure: { type: "f", value: null}
    }
}

export default Final;