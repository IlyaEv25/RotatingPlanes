import AddForces from "./shaders/AddForces";
//import Bloom from "./shaders/Bloom";
//import Blur from "./shaders/Blur";
import Accumulate from "./shaders/Accumulate";
import BloomUpsample from "./shaders/BloomUpsample";
import BloomDownsample from "./shaders/BloomDownsample";
import TAAResolve from "./shaders/TAAResolve";
import DeferedLight from "./shaders/DeferedLight";
import DepthMaterialParticles from "./shaders/DepthMaterialParticles";
import Final from "./shaders/Final";
import ForwardMaterial from "./shaders/ForwardMaterial";
import GBufferParticles from "./shaders/GBufferParticles";
import Gradient from "./shaders/Gradient";
import ModelToTexturePosition from "./shaders/ModelToTexturePosition";
import Simulation from "./shaders/Simulation";
import SkyMaterial from "./shaders/SkyMaterial";
import SSAO from "./shaders/SSAO";
import MotionBlur from "./shaders/MotionBlur";
import NeighbourMax from "./shaders/NeighbourMax";
import TileMax from "./shaders/TileMax";

export default () => {
  return {
    AddForces,
    //Bloom,
    //Blur,
    Accumulate,
    BloomUpsample,
    BloomDownsample,
    TAAResolve,
    DeferedLight,
    DepthMaterialParticles,
    Final,
    ForwardMaterial,
    GBufferParticles,
    Gradient,
    ModelToTexturePosition,
    Simulation,
    SkyMaterial,
    SSAO,
    MotionBlur,
    NeighbourMax,
    TileMax
  };
};
