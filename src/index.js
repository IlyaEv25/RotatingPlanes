import * as THREE from "three";

import Stats from "three/examples/jsm/libs/stats.module.js";
import { GUI } from "three/examples/jsm/libs/lil-gui.module.min.js";
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader.js";

import { EffectComposer } from "three/examples/jsm/postprocessing/EffectComposer.js";
import { RenderPass } from "three/examples/jsm/postprocessing/RenderPass.js";
import { UnrealBloomPass } from "./unreal";
import { ChromaticAberrationShader } from "./chromab";
import { ShaderPass } from "three/examples/jsm/postprocessing/ShaderPass.js";

import Pipeline from "./renderer";
import { DeferedMotionBlurBloomTAAPipeline } from "./pipelines";

import { CopyShader } from "three/examples/jsm/shaders/CopyShader.js";
import { FullScreenQuad } from "three/examples/jsm/postprocessing/Pass.js";
import { TWEEN } from "three/examples/jsm/libs/tween.module.min";

let camera,
  scene,
  renderer,
  stats,
  composer,
  renderPass,
  chromaticAberrationPass,
  model,
  bloomPass,
  fsQuad,
  posAnim,
  rotAnim,
  particles,
  pointer;
let camNear = 0.1;
let camFar = 75;
let tweens = [];
let tweensPos = [];
let tweensRot = [];
let timer = 0;

const params = {
  exposure: 1.5,
  camY: 0.06,
  bloomStrength: 4,
  bloomThreshold: 0.05,
  bloomRadius: 1.13,
  pixelRatio: 2,
  currentScroll: 0,
  delta: 0,
  target: [0, 0, 0],
  cursorAnimation: 0,
};

function onWindowResize() {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();

  chromaticAberrationPass.uniforms["resolution"].value = new THREE.Vector2(
    window.innerWidth * params.pixelRatio,
    window.innerHeight * params.pixelRatio
  );

  renderer.setSize(window.innerWidth, window.innerHeight);
  composer.setSize(window.innerWidth, window.innerHeight);
}

let scrollCallback = (e) => {
  var y_axis = new THREE.Vector3(0, 1, 0);
  var quaternion = new THREE.Quaternion();
  let pos = new THREE.Vector3(0, -3.5, 3.5); //new THREE.Vector3( 0, -3.5, 3.5 );//camera.position.clone();

  pos.applyQuaternion(quaternion.setFromAxisAngle(y_axis, Math.PI * (window.scrollY / (document.body.offsetHeight - window.innerHeight))));

  tweens.push(
    new TWEEN.Tween(camera.position)
      .to(
        {
          x: pos.x,
          y: pos.y,
          z: pos.z,
        },
        15
      )
      .onUpdate(() => {
        camera.lookAt(params.target[0], params.target[1], params.target[2]);
        camera.rotateOnAxis(new THREE.Vector3(0, 1, 0), params.camY * Math.PI);
      })
      .onComplete(() => {
        tweens.shift();
        if (tweens.length > 0) {
          let next = tweens[0];
          next.start();
        }
      })
  );

  if (tweens.length == 1) tweens[0].start();
};

let pointerCallback = (v) => (e) => {
  let newt = Date.now();
  let delta = newt - timer;
  if (delta < 10) return;
  timer = newt;

  if (Math.abs(e.movementX) < window.innerWidth / 100 && v == 1) return;

  let sign = e.movementX > -0.01 ? "+" : "-";

  //Position animation change

  tweensPos.push(
    new TWEEN.Tween(particles.position)
      .to(
        {
          y: sign + "0.001",
        },
        5
      )
      .easing(TWEEN.Easing.Bounce.Out)
      .onStart(() => {
        if (posAnim) posAnim.stop();
      })
      .onComplete(() => {
        tweensPos.shift();

        if (tweensPos.length > 0) {
          let next = tweensPos[0];
          next.start();
        } else if (posAnim) {
          posAnim.start();
          posAnim.repeat(Infinity);
        }
      })
  );

  if (tweensPos.length == 1) tweensPos[0].start();

  //Rotation animation change

  tweensRot.push(
    new TWEEN.Tween(model.rotation)
      .to(
        {
          y: sign + "0.006",
        },
        5
      )
      .easing(TWEEN.Easing.Bounce.Out)
      .onStart(() => {
        if (rotAnim) rotAnim.stop();
      })
      .onComplete(() => {
        tweensRot.shift();

        if (tweensRot.length > 0) {
          let next = tweensRot[0];
          next.start();
        } else if (rotAnim) {
          rotAnim.start();
          rotAnim.repeat(Infinity);
        }
      })
  );

  if (tweensRot.length == 1) tweensRot[0].start();
};

init();
animate();

class Scene extends THREE.Scene {
  constructor() {
    this.deferedMaterials = []; //materials, each has a mesh array
    this.forwardMaterials = [];
    this.shadowMaterial = []; //meshes
    this.camera = null;
    this.lights = [];
    this.invisible = [];
  }

  addDeferedMaterial(materialDescription){
    this.deferedMaterials.push({...materialDescription, meshes: [] });
  }

  addDefered(mesh, index) {
    this.deferedMaterials[index].meshes.push(mesh);
  }

  addLight(lightDescription, shadowCamera) {
    this.lights.push({...lightDescription, shadowCamera });
  }
  addCamera(camera)
  {
    this.camera = camera;
  }
}

function init() {
  //Scene

  scene = new Scene();

  // Renderer

//   renderer = new THREE.WebGLRenderer({
//     antialias: true,
//     precision: "highp",
//   });
//   renderer.setPixelRatio(params.pixelRatio);
//   renderer.setSize(window.innerWidth, window.innerHeight);

  renderer = new Pipeline(widnow.innerWidth, window,innerHeight, DeferedMotionBlurBloomTAAPipeline);
  renderer.renderer.setClearColor(0x0, 0);

  let container = document.getElementsByClassName("container")[0];
  container.appendChild(renderer.domElement);

  stats = new Stats();
  container.appendChild(stats.dom);

  // Camera

  camera = new THREE.PerspectiveCamera(30, window.innerWidth / window.innerHeight, camNear, camFar);
  camera.position.set(0, -3.5, 3.5);
  camera.lookAt(params.target[0], params.target[1], params.target[2]);
  camera.rotateOnAxis(new THREE.Vector3(0, 1, 0), params.camY * Math.PI);

  // Event Listeners

  pointer = pointerCallback(params.cursorAnimation);

  window.addEventListener("resize", onWindowResize);

  window.addEventListener("scroll", scrollCallback);

  window.addEventListener("pointermove", pointer);

  // Lights

//   const light1 = new THREE.PointLight(0xfff444, 0.4, 100);
//   light1.position.set(0, 0, 0.0);
//   scene.add(light1);

//   const light2 = new THREE.PointLight(0x0070ff, 0.8, 100);
//   light2.position.set(0, 10, 0);
//   scene.add(light2);

//   const light3 = new THREE.PointLight(0xcd00e1, 0.3, 100);
//   light3.position.set(10, 0, -10);
//   scene.add(light3);

//   const light4 = new THREE.PointLight(0xff6567, 0.5, 100);
//   light4.position.set(0, 0, 10);
//   scene.add(light4);

    let light1 = {
        position: THREE.Vector3(0, 0, 0.0),
        color: THREE.Color(0xffffff),
        intensity: 1.0,
        type: "POINT",
        attenuationRadius: 1.0,
        radius: 1.0,
        index: 0,
        shadowCamera: null,
    }

    let light2 = {
        position: THREE.Vector3(0, 10, 0),
        color: THREE.Color(0xffffff),
        intensity: 1.0,
        type: "POINT",
        attenuationRadius: 1.0,
        radius: 1.0,
        index: 0,
        shadowCamera: null,
    }

    let light3 = {
        position: THREE.Vector3(10, 0, -10),
        color: THREE.Color(0xffffff),
        intensity: 1.0,
        type: "POINT",
        attenuationRadius: 1.0,
        radius: 1.0,
        index: 0,
        shadowCamera: null,
    }
    let light4 = {
        position: THREE.Vector3(0, 0, 10),
        color: THREE.Color(0xffffff),
        intensity: 1.0,
        type: "POINT",
        attenuationRadius: 1.0,
        radius: 1.0,
        index: 0,
        shadowCamera: null,
    }


  //Geometry

  const sprite = new THREE.TextureLoader().load("../disc.png");

  let particleGeometry = new THREE.BufferGeometry();
  let cnt = 5000;

  let posArray = new Float32Array(cnt * 3);

  for (let i = 0; i < cnt * 3; i++) {
    posArray[i] = (Math.random() - 0.5) * 7;
  }
  particleGeometry.setAttribute("position", new THREE.BufferAttribute(posArray, 3));

  let materialP = new THREE.PointsMaterial({
    size: 0.02,
    map: sprite,
    alphaTest: 0.5,
    transparent: true,
  });

  particles = new THREE.Points(particleGeometry, materialP);
  scene.add(particles);

  posAnim = new TWEEN.Tween(particles.position).to(
    {
      y: "+1.0",
    },
    100000
  );

  posAnim.start();
  posAnim.repeat(Infinity);

  const loader = new GLTFLoader().setPath("../resources/scene/");
  loader.load("l4.glb", function (gltf) {
    model = gltf.scene;

    model.traverse((o) => {
      if (o.isMesh) o.material = new THREE.MeshPhysicalMaterial();
    });

    model.position.set(0, 0, 0);

    scene.add(model);

    rotAnim = new TWEEN.Tween(model.rotation).to(
      {
        y: "+6.28",
      },
      100000
    );

    rotAnim.start();
    rotAnim.repeat(Infinity);
  });

  // Render Passes

  //GUI

  const gui = new GUI(),
    folderLocal = gui.addFolder("Parameters"),
    propsLocal = {
      get Y() {
        return params.camY;
      },
      set Y(v) {
        params.camY = v;

        camera.lookAt(params.target[0], params.target[1], params.target[2]);
        camera.rotateOnAxis(new THREE.Vector3(0, 1, 0), v * Math.PI);
      },

      get bloom_str() {
        return bloomPass.strength;
      },
      set bloom_str(v) {
        bloomPass.strength = v;
      },

      get bloom_rad() {
        return bloomPass.radius;
      },
      set bloom_rad(v) {
        bloomPass.radius = v;
      },

      get bloom_thr() {
        return bloomPass.threshold;
      },
      set bloom_thr(v) {
        bloomPass.threshold = v;
      },

      get up() {
        return renderer.getPixelRatio();
      },
      set up(v) {
        renderer.setPixelRatio(v);
        composer.setPixelRatio(v);
        params.pixelRatio = v;
        onWindowResize();
      },

      get cursorAnimation() {
        return params.cursorAnimation;
      },
      set cursorAnimation(v) {
        params.cursorAnimation = v;
        window.removeEventListener("pointermove", pointer);
        pointer = pointerCallback(params.cursorAnimation);
        window.addEventListener("pointermove", pointer);
      },
    };

  folderLocal.add(propsLocal, "Y", -0.25, 0.25);
  folderLocal.add(propsLocal, "bloom_str", 0, 5);
  folderLocal.add(propsLocal, "bloom_rad", 0, 5);
  folderLocal.add(propsLocal, "bloom_thr", 0, 1);
  folderLocal.add(propsLocal, "up", 0.5, 5);
  folderLocal.add(propsLocal, "cursorAnimation", [0, 1]);
}

function animate() {
  requestAnimationFrame(animate);

  stats.begin();

  TWEEN.update();

  composer.render();
  //renderer.setRenderTarget(null);
  renderer.setClearColor(0x0e1946, 1);
  //renderer.clear();

  //console.log(fsQuad, composer);
  fsQuad.material.uniforms["tDiffuse"].value = composer.writeBuffer.texture;
  fsQuad.material.blending = THREE.AdditiveBlending;
  fsQuad.render(renderer);

  renderer.setClearColor(0x0, 0);

  stats.end();
}
