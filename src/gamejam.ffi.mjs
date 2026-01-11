import * as THREE from "three";

export function setSRGBColorSpace(texture) {
  texture.colorSpace = THREE.SRGBColorSpace;
  return texture;
}
