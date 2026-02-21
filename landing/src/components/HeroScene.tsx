"use client";

import { Canvas, useFrame } from "@react-three/fiber";
import { useRef, useMemo } from "react";
import * as THREE from "three";

function Particles() {
  const ref = useRef<THREE.Points>(null);
  const count = 120;

  const positions = useMemo(() => {
    const arr = new Float32Array(count * 3);
    for (let i = 0; i < count; i++) {
      arr[i * 3] = (Math.random() - 0.5) * 10;
      arr[i * 3 + 1] = (Math.random() - 0.5) * 8;
      arr[i * 3 + 2] = (Math.random() - 0.5) * 4;
    }
    return arr;
  }, []);

  useFrame(({ clock }) => {
    if (!ref.current) return;
    ref.current.rotation.y = clock.getElapsedTime() * 0.02;
    ref.current.rotation.x = Math.sin(clock.getElapsedTime() * 0.015) * 0.1;
  });

  return (
    <points ref={ref}>
      <bufferGeometry>
        <bufferAttribute
          attach="attributes-position"
          args={[positions, 3]}
        />
      </bufferGeometry>
      <pointsMaterial
        size={0.03}
        color="#2563eb"
        transparent
        opacity={0.35}
        sizeAttenuation
      />
    </points>
  );
}

function FloatingMesh() {
  const ref = useRef<THREE.Mesh>(null);

  useFrame(({ clock }) => {
    if (!ref.current) return;
    ref.current.rotation.x = clock.getElapsedTime() * 0.08;
    ref.current.rotation.z = clock.getElapsedTime() * 0.05;
    ref.current.position.y = Math.sin(clock.getElapsedTime() * 0.3) * 0.3;
  });

  return (
    <mesh ref={ref} scale={2.5}>
      <icosahedronGeometry args={[1, 1]} />
      <meshBasicMaterial
        color="#2563eb"
        wireframe
        transparent
        opacity={0.06}
      />
    </mesh>
  );
}

export default function HeroScene() {
  return (
    <div className="absolute inset-0 opacity-60">
      <Canvas
        camera={{ position: [0, 0, 6], fov: 45 }}
        dpr={[1, 1.5]}
        gl={{ antialias: true, alpha: true }}
        style={{ background: "transparent" }}
      >
        <Particles />
        <FloatingMesh />
      </Canvas>
    </div>
  );
}
