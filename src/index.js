import * as THREE from 'three';

import Stats from 'three/examples/jsm/libs/stats.module.js';
import { GUI } from 'three/examples/jsm/libs/lil-gui.module.min.js';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';

import { EffectComposer } from 'three/examples/jsm/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/examples/jsm/postprocessing/RenderPass.js';
import { UnrealBloomPass } from './unreal';
import { ChromaticAberrationShader } from './chromab';
import { ShaderPass } from 'three/examples/jsm/postprocessing/ShaderPass.js';

import { CopyShader } from 'three/examples/jsm/shaders/CopyShader.js';
import { FullScreenQuad } from 'three/examples/jsm/postprocessing/Pass.js';
import { TWEEN } from 'three/examples/jsm/libs/tween.module.min'




let camera, scene, renderer, startTime, stats, composer, renderPass, chromaticAberrationPass, model, prev_time, bloomPass, fsQuad, rotAnim, rotAnimInv;
let camNear = 0.1;
let camFar = 75;


const params = {
    exposure: 1.5,
    camY: 0.06,
    bloomStrength: 4,
    bloomThreshold: 0.05,
    bloomRadius: 1.13,
    pixelRatio: 2
}

init();
animate();

function init() {

    //Scene 

    scene = new THREE.Scene();

    stats = new Stats();
    document.body.appendChild( stats.dom );

    // Renderer

    renderer = new THREE.WebGLRenderer({
        antialias: true,
        precision: 'highp'
    });
    renderer.setPixelRatio( params.pixelRatio );
    renderer.setSize( window.innerWidth, window.innerHeight );
    renderer.setClearColor(0x0, 0)

    // Camera

    camera = new THREE.PerspectiveCamera( 30, window.innerWidth / window.innerHeight, camNear, camFar );
    camera.position.set( 0, -3.5, 3.5 );
    camera.lookAt(0, 0., 0)
    camera.rotateOnAxis(new THREE.Vector3(0, 1, 0), params.camY * Math.PI);

    // Event Listeners

    window.addEventListener( 'resize', onWindowResize );
    window.addEventListener( 'wheel', (e) => {
        var y_axis = new THREE.Vector3( 0, 1, 0 );
        var quaternion = new THREE.Quaternion;
        let pos = camera.position.clone();
        
        pos.applyQuaternion(quaternion.setFromAxisAngle(y_axis, e.deltaY/500));
        new TWEEN.Tween(camera.position)
            .to(
                {
                    x: pos.x,
                    y: pos.y,
                    z: pos.z,
                },
                500
            ).onStart(() => {
                if (rotAnim) {
                    rotAnim.stop();
                    rotAnimInv.stop();
                }
            }).onUpdate(() => {
                //camera.position.copy(pos);
                camera.lookAt(0, 0, 0);
                camera.rotateOnAxis(new THREE.Vector3(0, 1, 0), params.camY * Math.PI);
                if (rotAnim) {

                    if (e.deltaY > 0) {
                        rotAnim.stop();
                        rotAnimInv.start();
                    }
                    else {
                        rotAnimInv.stop();
                        rotAnim.start();
                    }
                }
            })
            .start()

    });
    document.body.appendChild( renderer.domElement );

    // Lights

    const light1 = new THREE.PointLight( 0xFFF444, 0.4, 100 );
    light1.position.set( 0, 0, 0.0 );
    scene.add( light1 );

    const light2 = new THREE.PointLight( 0x0070FF, 0.8, 100 );
    light2.position.set( 0, 10, 0 );
    scene.add( light2 );

    const light3 = new THREE.PointLight( 0xCD00E1, 0.3, 100 );
    light3.position.set( 10, 0, -10 );
    scene.add( light3 );

    const light4 = new THREE.PointLight( 0xFF6567, 0.5, 100 );
    light4.position.set( 0, 0, 10 );
    scene.add( light4 );

    //Geometry

    const sprite = new THREE.TextureLoader().load( '../disc.png' );

    let particleGeometry = new THREE.BufferGeometry();
    let cnt = 5000;

    let posArray = new Float32Array(cnt* 3);

    for(let i = 0; i < cnt * 3; i++) {
        posArray[i] = (Math.random() - 0.5) * 5;
    }
    particleGeometry.setAttribute('position', new THREE.BufferAttribute(posArray, 3));

    let materialP = new THREE.PointsMaterial({
        size: 0.02,
        map: sprite,
        alphaTest: 0.5, 
        transparent: true
    })

    let particles = new THREE.Points(particleGeometry, materialP);
    scene.add(particles);

    const loader = new GLTFLoader().setPath( '../resources/scene/' );
    loader.load( 'l4.glb', function ( gltf ) {

        model = gltf.scene;

        model.traverse((o) => { if (o.isMesh) o.material = new THREE.MeshPhysicalMaterial(); });
          

        model.position.set(0,0,0);

        scene.add( model );

        rotAnim = new TWEEN.Tween(model.rotation)
            .to(
                {
                    x: model.rotation.x,
                    y: model.rotation.y - 2 * Math.PI,
                    z: model.rotation.z,
                },
                300000
            )

        rotAnimInv = new TWEEN.Tween(model.rotation)
        .to(
            {
                x: model.rotation.x,
                y: model.rotation.y + 2 * Math.PI,
                z: model.rotation.z,
            },
            300000
        )

        rotAnim.start()
        rotAnim.repeat(Infinity)


    } );


    // Render Passes


    composer = new EffectComposer( renderer);
    composer.renderToScreen = false;

    renderPass = new RenderPass( scene, camera );
    renderPass.clearColor = 0x0;
    composer.addPass( renderPass );

    bloomPass = new UnrealBloomPass( new THREE.Vector2( window.innerWidth, window.innerHeight ), 1.5, 0.4, 0.85 );
    bloomPass.threshold = params.bloomThreshold;
    bloomPass.strength = params.bloomStrength;
    bloomPass.radius = params.bloomRadius;

    // bloomPass.materialCopy.blending = THREE.CustomBlending;
    // bloomPass.materialCopy.blendEquation = THREE.AddEquation; //default
    // bloomPass.materialCopy.blendSrc = THREE.OneFactor;//THREE.OneFactor; //default
    // bloomPass.materialCopy.blendDst = THREE.ZeroFactor;//THREE.OneFactor;
    // bloomPass.materialCopy.blendSrcAlpha = THREE.OneFactor;//THREE.SrcAlphaFactor;
    // bloomPass.materialCopy.blendDstAlpha = THREE.OneFactor;//THREE.DstAlphaFactor;
    
    composer.addPass( bloomPass );
    

    ChromaticAberrationShader.uniforms = {
        tDiffuse: { type: "t", value: null },
        resolution: {
            value: new THREE.Vector2(
                window.innerWidth * params.pixelRatio,
                window.innerHeight * params.pixelRatio
            )
        },
        power: { value: 0.5 }
    }

	chromaticAberrationPass = new ShaderPass(ChromaticAberrationShader);
    chromaticAberrationPass.renderToScreen = false;
    chromaticAberrationPass.needsSwap = false;

    composer.addPass(chromaticAberrationPass);


    let finalPassMaterial = new THREE.ShaderMaterial( {

        defines: {},
        uniforms: CopyShader.uniforms,
        vertexShader: CopyShader.vertexShader,
        fragmentShader: CopyShader.fragmentShader
    } )

    fsQuad = new FullScreenQuad(finalPassMaterial);

    //GUI

    const gui = new GUI(),
        folderLocal = gui.addFolder( 'Parameters' ),
        propsLocal = {

            get 'Y'() {

                return params.camY;

            },
            set 'Y'( v ) {

                params.camY = v;

                camera.lookAt(0, 0, 0);
                camera.rotateOnAxis(new THREE.Vector3(0, 1, 0), v * Math.PI);

            },

            get 'bloom_str'() {

                return bloomPass.strength;

            },
            set 'bloom_str'( v ) {

                bloomPass.strength = v;

            },

            get 'bloom_rad'() {

                return bloomPass.radius;

            },
            set 'bloom_rad'( v ) {

                bloomPass.radius = v;

            },

            get 'bloom_thr'() {

                return bloomPass.threshold;

            },
            set 'bloom_thr'( v ) {

                bloomPass.threshold = v;

            },

            get 'up'() {

                return renderer.getPixelRatio();

            },
            set 'up'( v ) {

                renderer.setPixelRatio(v);
                composer.setPixelRatio(v);
                chromaticAberrationPass.material.uniforms['resolution'].value = new THREE.Vector2(
					window.innerWidth * v,
					window.innerHeight * v
                );

            }
        

        }
    
    folderLocal.add( propsLocal, 'Y' , -0.25, 0.25);
    folderLocal.add(propsLocal, 'bloom_str', 0, 5);
    folderLocal.add(propsLocal, 'bloom_rad', 0, 5);
    folderLocal.add(propsLocal, 'bloom_thr', 0, 1);
    folderLocal.add(propsLocal, 'up', 0.5, 5);

    //Start Time

    startTime = Date.now();


}

function onWindowResize() {

    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();

    chromaticAberrationPass.uniforms['resolution'].value = new THREE.Vector2 (
        window.innerWidth * params.pixelRatio,
        window.innerHeight * params.pixelRatio
    )

    renderer.setSize( window.innerWidth, window.innerHeight );
    composer.setSize( window.innerWidth, window.innerHeight );

}

function animate() {

    const currentTime = Date.now();
    const time = ( currentTime - startTime ) / 1000;
    const delta = time- prev_time;
    prev_time = time;

    requestAnimationFrame( animate );

    stats.begin();

    TWEEN.update();

    composer.render();
    //renderer.setRenderTarget(null);
    renderer.setClearColor(0x0E1946, 1);
    //renderer.clear();

    //console.log(fsQuad, composer);
    fsQuad.material.uniforms['tDiffuse'].value = composer.writeBuffer.texture;
    fsQuad.material.blending = THREE.AdditiveBlending;
    fsQuad.render(renderer);

    renderer.setClearColor(0x0, 0);

    stats.end();

}
