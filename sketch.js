// Reference: https://docs.ml5js.org/#/reference/bodypose
// Code: https://editor.p5js.org/ml5/sketches/hMN9GdrO3

let state;

function preload() {
  state = new State();
  state.preload();
}

function setup() {
  state.setup();
}

function draw() {
  state.draw();
}
