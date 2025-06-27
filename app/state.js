function vec2str(vec, precision = 2) {
  return `(${vec.x.toFixed(precision)}, ${vec.y.toFixed(precision)}, ${vec.z.toFixed(precision)})`;
}

function floatToBytes(n) {
  return new Float64Array([n]);
}

function floatsToBlob(...floats) {
  // TODO why can't add many floats in one float array
  // new Float64Array([Date.now(), neck_centre.y, neck_centre.z])
  return new Blob(
    floats.map(float => floatToBytes(float)),
    {
      type: "application/octet-stream",
    }
  );
}

function postMessage(message) {
  fetch("/data", {
    method: "POST",
    headers: {
      "Content-Type": "application/octet-stream",
    },
    body: message,
  });
}

class State {
  preload() {
    // Load the bodyPose model
    this.bodyPose = ml5.bodyPose("BlazePose");

    this.faceMesh = ml5.faceMesh({
      maxFaces: 1,
      // refineLandmarks: false,
    });
  }

  setup() {
    const size = min(windowWidth, windowHeight);
    createCanvas(size, size, WEBGL);
    angleMode(DEGREES);
    debugMode();

    // using ideal: max is "not officially supported" according to ChatGPT, but it works in Chrome on Windows
    // In Firefox: DOMException: Failed to allocate videosource
    // using 4096x2160 gives full HD resolution on laptop, but on Pixel it chooses the rear camera. Could further enforce using the front camera

    // by default, the resolution is 640x480, with cropped field of view
    const constraints = {
      video: {
        width: { ideal: 1920 },
        height: { ideal: 1080 },
      },
      audio: false,
    };
    this.video = createCapture(constraints);
    this.infoElement = select("#info");
    this.warningElement = select("#warning");
    this.saveElement = select("#save");

    // Start detecting poses in the webcam video
    this.bodyPose.detectStart(this.video, poses => {
      // TODO could choose pose with highest confidence
      this.pose = poses[0];
    });

    this.faceMesh.detectStart(this.video, faces => {
      // faces can be empty if no face detected, even if the callback is called
      if (faces.length === 0) {
        return;
      }
      //   TODO could choose face with highest confidence
      this.face = faces[0];

      // order of operations seems to be face callback - draw() - screen_update
      // so any drawing here in callback gets cleared by background() call in draw

      this.face.keypoints = this.face.keypoints.map(point =>
        createVector(point.x, point.y, point.z)
      );

      // this.face.keypoints = this.face.keypoints.map(point => p5.Vector.div(point, this.get_eye_dist()));

      if (this.initial_neck_centre_requested) {
        this.initial_neck_centre = this.get_neck_centre();
        this.initial_neck_centre_requested = false;
      }

      this.head_detection();
    });

    // Get the skeleton connection information
    this.connections = this.bodyPose.getSkeleton();
    this.triangle_mesh = this.faceMesh.getTriangles();

    this.CONFIDENCE_THRESHOLD = 0.1;

    let button_centre = createButton("Centre Face");
    button_centre.mousePressed(() => {
      this.initial_neck_centre_requested = true;
    });
    button_centre.position(200, 200);
    button_centre.style("font-size", "40px");
  }

  draw() {
    scale(height / 2);
    orbitControl();
    background(10, 0, 20);

    this.drawFace();
    // this.drawSkeleton();

    // const dims = `video: ${this.video.width}x${this.video.height}\ncanvas: ${width}x${height}\nWindow: ${windowWidth}x${windowHeight}`;
    // this.infoElement.html(dims);
  }

  draw_box(pos, size = 0.03) {
    push();
    translate(pos);
    box(size);
    pop();
  }

  drawFace() {
    if (!this.face) {
      return;
    }

    stroke(0, 255, 0);
    strokeWeight(4);

    const draw_scale = 300;

    // TODO now boxes not being drawn
    for (const point of this.face.keypoints) {
      this.draw_box(
        p5.Vector.div(p5.Vector.sub(point, this.initial_neck_centre), draw_scale),
        0.02
      );
    }

    for (const [idxA, idxB] of this.triangle_mesh) {
      const a = p5.Vector.div(
        p5.Vector.sub(this.face.keypoints[idxA], this.initial_neck_centre),
        draw_scale
      );
      const b = p5.Vector.div(
        p5.Vector.sub(this.face.keypoints[idxB], this.initial_neck_centre),
        draw_scale
      );
      line(a.x, a.y, a.z, b.x, b.y, b.z);
    }

    stroke(255, 0, 0);
    this.draw_box(
      p5.Vector.div(p5.Vector.sub(this.get_neck_centre(), this.initial_neck_centre), draw_scale),
      0.045
    );

    stroke(255, 255, 255);
  }

  drawSkeleton() {
    if (!this.pose) {
      return; // No pose detected, nothing to draw
    }

    for (const [pointAIndex, pointBIndex] of this.connections) {
      const pointA = this.pose.keypoints3D[pointAIndex];
      const pointB = this.pose.keypoints3D[pointBIndex];
      // Only draw a line if both points are confident enough
      if (
        pointA.confidence > this.CONFIDENCE_THRESHOLD &&
        pointB.confidence > this.CONFIDENCE_THRESHOLD
      ) {
        stroke(0, 255, 255);
        strokeWeight(4);
        beginShape();
        vertex(pointA.x, pointA.y, pointA.z);
        vertex(pointB.x, pointB.y, pointB.z);
        endShape();
      }
    }

    // Draw keypoints as rotating 3D boxes
    for (let i = 0; i < this.pose.keypoints.length; i++) {
      let keypoint = this.pose.keypoints3D[i];
      stroke(255, 0, 255);
      strokeWeight(1);
      // fill(255, 150);

      if (keypoint.confidence > 0.1) {
        push();
        translate(keypoint.x, keypoint.y, keypoint.z);
        box(0.09);
        pop();
      }
    }

    // Draw a ground plane
    push();
    stroke(255);
    rectMode(CENTER);
    strokeWeight(1);
    fill(255, 100);
    // TODO ground plane transform breaks on panning
    translate(0, 1);
    rotateX(90);
    // square(0, 0, 2);
    pop();
  }

  keypointPos(name) {
    if (!this.pose) {
      return;
    }
    const keypoint_ = this.pose[name];
    if (!keypoint_) {
      return;
    }
    return createVector(keypoint_.keypoint3D.x, keypoint_.keypoint3D.y, keypoint_.keypoint3D.z);
  }

  get_eye_dist() {
    return p5.Vector.dist(this.face.keypoints[362], this.face.keypoints[133]);
  }

  get_neck_centre() {
    // return p5.Vector.div(p5.Vector.add(this.face.keypoints[93], this.face.keypoints[393]), 2);
    const sum = this.face.keypoints.reduce(
      (accumulator, currentValue) => p5.Vector.add(accumulator, currentValue),
      createVector(0, 0, 0)
    );
    return p5.Vector.div(sum, this.face.keypoints.length);
  }

  head_detection() {
    if (!this.face) {
      return;
    }

    const neck_centre = p5.Vector.div(
      p5.Vector.sub(this.get_neck_centre(), this.initial_neck_centre),
      this.get_eye_dist()
    );
    this.infoElement.html(vec2str(neck_centre));
    // message format: float64:timestamp float64:value
    postMessage(floatsToBlob(Date.now(), -neck_centre.y, neck_centre.x));
  }

  head_turn_detection() {
    const nose = this.keypointPos("nose");

    if (!nose) {
      return;
    }

    const heading = this.heading;

    if (!this.min_heading || !this.max_heading) {
      return;
    }

    const relative_turn = map(heading, this.min_heading, this.max_heading, 0, 90);

    // message format: float64:timestamp float64:value
    postMessage(floatsToBlob(Date.now(), relative_turn));

    let str = `Min: ${this.min_heading.toFixed(2)} | Max: ${this.max_heading.toFixed(
      2
    )} | Cur: ${heading.toFixed(2)} | Scaled: ${relative_turn.toFixed(2)}`;
    let warning = "";

    this.infoElement.html(str);
  }
}
