import * as THREE from "three";
import { ShaderPass } from "three/examples/jsm/postprocessing/ShaderPass";
import * as passes from "./passes";
import shaderLoad from "./shaders";

let quad;
let shaders = shaderLoad();
//let ShaderPass = loadShaderPass(THREE);

let lightTypeMap = {
  "AREA": 0,
  "POINT": 1
}

class GeneralRenderPass {
  constructor(name, uniforms, numColorTargets, isDepthTarget, width, height, clear, textureType) {
    this.name = name;
    this.clear = clear;
    if (!(textureType == "Final")) {
      this.renderTarget = new THREE.WebGLMultipleRenderTargets(width, height, numColorTargets, {
        type: textureType,
        //type: THREE.HalfFloatType,
        wrapS: THREE.ClampToEdgeWrapping,
        wrapT: THREE.ClampToEdgeWrapping,
        format: THREE.RGBAFormat,
        minFilter: THREE.LinearFilter,
        magFiler: THREE.LinearFilter,
        stencilBuffer: false,
        depthBuffer: isDepthTarget,
      });

      this.previousRenderTarget = new THREE.WebGLMultipleRenderTargets(width, height, numColorTargets, {
        type: textureType,
        //type: THREE.HalfFloatType,
        wrapS: THREE.ClampToEdgeWrapping,
        wrapT: THREE.ClampToEdgeWrapping,
        format: THREE.RGBAFormat,
        minFilter: THREE.LinearFilter,
        magFiler: THREE.LinearFilter,
        stencilBuffer: false,
        depthBuffer: isDepthTarget,
      });

      // depthTexture: new THREE.DepthTexture(
      //   shadowMapSize,
      //   shadowMapSize,
      //   THREE.UnsignedIntType,
      //   THREE.UVMapping,
      //   THREE.ClampToEdgeWrapping,
      //   THREE.ClampToEdgeWrapping,
      //   THREE.NearestFilter,
      //   THREE.NearestFilter,
      //   1.0,
      //   THREE.DepthFormat
      // ),

      if (isDepthTarget) {
        this.renderTarget.depthTexture = new THREE.DepthTexture(width, height);
        this.renderTarget.depthTexture.format = THREE.DepthFormat;
        this.renderTarget.depthTexture.type = THREE.FloatType;

        this.previousRenderTarget.depthTexture = new THREE.DepthTexture(width, height);
        this.previousRenderTarget.depthTexture.format = THREE.DepthFormat;
        this.previousRenderTarget.depthTexture.type = THREE.FloatType;
      }
    } else this.renderTarget = null;

    this.width = width;
    this.height = height;
    this.uniforms = THREE.UniformsUtils.clone(uniforms);
    this.renderCounter = -2;
  }

  updateUniforms(uniformObject) {
    if (this.uniforms["u_counter"]) this.uniforms["u_counter"].value = this.renderCounter;

    Object.keys(this.uniforms).forEach((key) => {
      if (key in uniformObject) this.uniforms[key].value = uniformObject[key];
    });
  }

  updateDependencies(dependencyGraph) {
    let dependencies = dependencyGraph[this.name];
    dependencies.forEach((dependency) => {
      let index = dependency.channel;

      if (dependency.type == "color") this.uniforms[dependency.uniform].value = dependency.instance.renderTarget.texture[index];
      else this.uniforms[dependency.uniform].value = dependency.instance.renderTarget.depthTexture;
    });
  }

  render(renderer, scene, camera, uniformObject, dependencyGraph) {
    renderer.setRenderTarget(this.renderTarget);
    if (this.clear) renderer.clear();
    this.renderCounter++;
    this.renderCounter = this.renderCounter % 8.0;
    this.updateUniforms(uniformObject);
    this.updateDependencies(dependencyGraph);
  }
}

class QuadPass extends GeneralRenderPass {
  constructor(name, shader, numColorTargets, isDepthTarget, width, height, clear, textureType) {
    super(name, shader.uniforms, numColorTargets, isDepthTarget, width, height, clear, textureType);
    this.pass = new ShaderPass({
      uniforms: this.uniforms,
      vertexShader: shader.vertexShader,
      fragmentShader: shader.fragmentShader,
      defines: shader.defines,
    });
    this.uniforms = this.pass.uniforms;
    this.pass.renderToScreen = textureType == "Final";
  }

  render(renderer, scene, camera, uniformObject, dependencyGraph) {
    super.render(renderer, scene, camera, uniformObject, dependencyGraph);
    this.pass.render(renderer, this.renderTarget);
  }
}

class ScenePass extends GeneralRenderPass {
  constructor(name, uniforms, numColorTargets, isDepthTarget, width, height, clear, textureType) {
    super(name, uniforms, numColorTargets, isDepthTarget, width, height, clear, textureType);
  }

  render(renderer, scene, camera, uniformObject, dependencyGraph) {
    super.render(renderer, scene, camera, uniformObject, dependencyGraph);
    renderer.render(scene, camera);
  }
}

class OverrideMaterialScenePass extends GeneralRenderPass {
  constructor(name, shader, numColorTargets, isDepthTarget, width, height, clear, textureType) {
    super(name, shader.uniforms, numColorTargets, isDepthTarget, width, height, clear, textureType);
    this.material = new THREE.RawShaderMaterial({
      uniforms: this.uniforms,
      vertexShader: shader.vertexShader,
      fragmentShader: shader.fragmentShader,
      defines: shader.defines,
    });
    this.material.glslVersion = THREE.GLSL3;
    //this.material.isMeshStandardMaterial = true;
    this.material.onBeforeRender = (_this, scene, camera, geometry, object, group) => {
      if (this.uniforms["modelViewMatrix"]) this.uniforms["modelViewMatrix"].value = object.modelViewMatrix;
      if (this.uniforms["modelMatrix"]) this.uniforms["modelMatrix"].value = object.matrixWorld;
      if (this.uniforms["projectionMatrix"]) this.uniforms["projectionMatrix"].value = camera.projectionMatrix;
    };
    //material.onBeforeRender( _this, scene, camera, geometry, object, group );
  }

  render(renderer, scene, camera, uniformObject, dependencyGraph) {
    super.render(renderer, scene, camera, uniformObject, dependencyGraph);
    scene.forwardObjects.forEach((o) => {
      o.visible = false;
    });
    scene.deferedObjects.forEach((o) => {
      o.visible = true;
    });
    scene.overrideMaterial = this.material;
    renderer.render(scene, camera);
    scene.overrideMaterial = null;
    scene.forwardObjects.forEach((o) => {
      o.visible = true;
    });
    scene.deferedObjects.forEach((o) => {
      o.visible = true;
    });
  }
}

class GBufferPass extends GeneralRenderPass {
  constructor(name, shader, numColorTargets, isDepthTarget, width, height, clear, textureType) {
    super(name, shader.uniforms, numColorTargets, isDepthTarget, width, height, clear, textureType);
    this.material = new THREE.RawShaderMaterial({
      uniforms: this.uniforms,
      vertexShader: shader.vertexShader,
      fragmentShader: shader.fragmentShader,
      defines: shader.defines,
    });
    this.material.glslVersion = THREE.GLSL3;
    //this.material.isMeshStandardMaterial = true;
    this.material.onBeforeRender = (_this, scene, camera, geometry, object, group) => {
      if (this.uniforms["modelViewMatrix"]) this.uniforms["modelViewMatrix"].value = object.modelViewMatrix;
      if (this.uniforms["modelMatrix"]) this.uniforms["modelMatrix"].value = object.matrixWorld;
      if (this.uniforms["projectionMatrix"]) this.uniforms["projectionMatrix"].value = camera.projectionMatrix;
    };
  }

  render(renderer, scene, camera, uniformObject, dependencyGraph) {
    super.render(renderer, scene, camera, uniformObject, dependencyGraph);
    scene.forwardMaterials.forEach((material) => {
      material.meshes.forEach((mesh) => {
        mesh.visible = false;
      });
    });
    scene.deferedMaterials.forEach((material) => {
      let roughness = material.roughness;
      let metallic = material.metallic;
      let emissiveColor = material.emissiveColor;
      let emissiveStrength = material.emissiveStrength;
      let color = material.color;

      material.meshes.forEach((mesh) => {
        mesh.visible = true;
        mesh.material = this.material;
        mesh.material.uniforms.color.value = new THREE.Color(color);
        mesh.material.uniforms.roughness.value = roughness;
        mesh.material.uniforms.emissiveColor.value = new THREE.Color(emissiveColor);
        mesh.material.uniforms.metallic.value = metallic;
        mesh.material.uniforms.emissiveStrength.value = emissiveStrength;
      });
    });

    renderer.render(scene, camera);

    scene.forwardMaterials.forEach((material) => {
      material.meshes.forEach((mesh) => {
        mesh.visible = false;
      });
    });
  }
}

class QuadOverForwardScenePass extends GeneralRenderPass {
  constructor(name, shader, numColorTargets, isDepthTarget, width, height, clear, textureType) {
    super(name, shader.uniforms, numColorTargets, isDepthTarget, width, height, clear, textureType);
    this.pass = new ShaderPass({
      uniforms: this.uniforms,
      vertexShader: shader.vertexShader,
      fragmentShader: shader.fragmentShader,
      defines: shader.defines,
    });
    this.pass.fsQuad.material.transparent = true;
    this.pass.fsQuad.material.blending = THREE.NormalBlending;
    this.uniforms = this.pass.uniforms;
    this.pass.renderToScreen = textureType == "Final";
  }

  render(renderer, scene, camera, uniformObject, dependencyGraph) {
    super.render(renderer, scene, camera, uniformObject, dependencyGraph);
    scene.forwardMaterials.forEach((material) => {
      material.meshes.forEach((mesh) => {
        mesh.visible = true;
      });
    });
    scene.deferedMaterials.forEach((material) => {
      material.meshes.forEach((mesh) => {
        mesh.visible = false;
      });
    });
    renderer.render(scene, camera);
    this.pass.render(renderer, this.renderTarget);
  }
}

class LightPass extends QuadOverForwardScenePass {
  constructor(name, shader, numColorTargets, isDepthTarget, width, height, clear, textureType) {
    super(name, shader.uniforms, numColorTargets, isDepthTarget, width, height, clear, textureType);
    this.N = 0;
    this.shadowPasses = [];
  }

  buildShadowPass() {
    let shadowDescription = passes["shadow"]();
    this.shadowPasses.push(
      new OverrideMaterialScenePass("shadow" + this.N, shadowDescription.shader, 1, true, this.width, this.height, true, THREE.FloatType)
    );
    this.N++;
  }

  render(renderer, scene, camera, uniformObject, dependencyGraph) {
    this.uniforms["lights"].value = [];
    this.uniforms["u_shadow_depth"].value = [];


    if (scene.lights.length > this.N)
      for (let i = this.N; i < scene.lights.length; i++)
        this.buildShadowPass();

    scene.lights.forEach((light, index) => {

      this.shadowPasses[index].render(renderer, scene, light.shadowCamera, uniformObject, dependencyGraph);
      this.uniforms["lights"].value.push({
        position: light.position,
        intensity: light.intensity,
        color: light.color,
        intensity: light.intensity,
        type: lightTypeMap[light.type],
        attenuationRadius: light.attenuationRadius,
        radius: light.radius,
        useShadow: light.useShadow
      });
      this.uniforms["u_shadow_depth"].value.push(this.shadowPasses[index].renderTarget.depthTexture);
    });
    super.render(renderer, scene, camera, uniformObject, dependencyGraph);
  }
}

let typePassMap = {
  LightPass: LightPass,
  GBufferPass: GBufferPass,
  OverrideMaterialScenePass: OverrideMaterialScenePass,
  QuadOverForwardScenePass: QuadOverForwardScenePass,
  ScenePass: ScenePass,
  QuadPass: QuadPass,
};

class Pipeline {
  constructor(width, height, pipelineDescription) {
    this.renderer = new THREE.WebGLRenderer({ antialias: true });
    this.renderer.setClearAlpha(0.0);
    this.domElement = this.renderer.domElement;
    this.renderer.setSize(width, height);
    this.renderer.setPixelRatio(1);
    this.dependencyGraph = pipelineDescription.dependencies;
    this.renderPipeline = [];
    this.passMap = {};

    pipelineDescription.pipe.forEach((passName) => {
      let passDescription = passes[passName]();
      let sizes = { width, height };
      let passSizes = { width: passDescription.width(sizes), height: passDescription.height(sizes) };
      let args = passDescription.shaderArguments == "size" ? passSizes : null;

      let pass = new typePassMap[passDescription.type](
        passName,
        args ? passDescription.shader(args) : passDescription.shader,
        passDescription.numberOfColorAttachments,
        passDescription.isDepthTarget,
        passSizes.width,
        passSizes.height,
        passDescription.clear,
        passDescription.textureType
      );
      this.renderPipeline.push(pass);
      this.passMap[passName] = pass;
    });
    this.fillDependencyGraphWithInstanceReferences();
  }

  setSize(width, height) {
    this.renderer.setSize(width, height);
  }

  fillDependencyGraphWithInstanceReferences() {
    Object.values(this.dependencyGraph).forEach((dependencies) => {
      dependencies.forEach((dependency) => {
        dependency.instance = this.passMap[dependency.pass];
      });
    });
  }

  render(scene, uniformObject) {
    let renderer = this.renderer;
    this.renderPipeline.forEach((pass) => {
      if (pass.name != "shadow") pass.render(renderer, scene, camera, uniformObject, this.dependencyGraph);
      else pass.render(renderer, scene, shadowCamera, uniformObject, this.dependencyGraph);
    });
  }
}

export default Pipeline;
