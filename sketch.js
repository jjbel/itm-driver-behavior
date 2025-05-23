/*
 * 👋 Hello! This is an ml5.js example made and shared with ❤️.
 * Learn more about the ml5.js project: https://ml5js.org/
 * ml5.js license and Code of Conduct: https://github.com/ml5js/ml5-next-gen/blob/main/LICENSE.md
 *
 * This example demonstrates drawing skeletons on poses for the MoveNet model.
 */

// Reference: https://docs.ml5js.org/#/reference/bodypose
// Code: https://editor.p5js.org/ml5/sketches/hMN9GdrO3

let video;
let bodyPose;
let poses = [];
let connections;

function preload() {
  // Load the bodyPose model
  console.log("Loading BodyPose model...");
  bodyPose = ml5.bodyPose();
  console.log("done");
}

function setup() {
  createCanvas(windowWidth, windowHeight);

  // Create the video and hide it
  video = createCapture(VIDEO);
  video.size(width, height);
  video.hide();

  // Start detecting poses in the webcam video
  bodyPose.detectStart(video, gotPoses);
  // Get the skeleton connection information
  connections = bodyPose.getSkeleton();
}

function draw() {
  // Draw the webcam video
  background(10, 0, 20);
  image(video, 0, 0, width, height);
  drawSkeleton();

  const date = new Date();

  // TODO figure out why 2 huge delays, one when loading, other before camera feed starts
  // for profiling:
  // console.log(
  //   date.getSeconds() + "." + date.getMilliseconds(),
  //   video.width,
  //   video.height,
  //   width,
  //   height
  // );

  textSize(20);
  textAlign(CENTER, CENTER);
  text(`width: ${video.width} height: ${video.height}`, width / 2, height / 2);
}

// Callback function for when bodyPose outputs data
function gotPoses(results) {
  poses = results;
}

function drawSkeleton() {
  // Draw the skeleton connections
  for (let i = 0; i < poses.length; i++) {
    let pose = poses[i];
    for (let j = 0; j < connections.length; j++) {
      let pointAIndex = connections[j][0];
      let pointBIndex = connections[j][1];
      let pointA = pose.keypoints[pointAIndex];
      let pointB = pose.keypoints[pointBIndex];
      // Only draw a line if both points are confident enough
      if (pointA.confidence > 0.1 && pointB.confidence > 0.1) {
        stroke(255, 0, 0);
        strokeWeight(2);
        line(pointA.x, pointA.y, pointB.x, pointB.y);
      }
    }
  }

  // Draw all the tracked landmark points
  for (let i = 0; i < poses.length; i++) {
    let pose = poses[i];
    for (let j = 0; j < pose.keypoints.length; j++) {
      let keypoint = pose.keypoints[j];
      // Only draw a circle if the keypoint's confidence is bigger than 0.1
      if (keypoint.confidence > 0.1) {
        fill(0, 255, 0);
        noStroke();
        circle(keypoint.x, keypoint.y, 10);
      }
    }
  }
}
