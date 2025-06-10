class State {
  preload() {
    // Load the bodyPose model
    console.log("Loading BodyPose model...");
    this.bodyPose = ml5.bodyPose("BlazePose");
    this.faceMesh = ml5.faceMesh({
      maxFaces: 1,
      // refineLandmarks: false,
      // flipHorizontal: false,
    });
    console.log("done");
  }

  setup() {
    // createCanvas(windowWidth, windowHeight);
    const size = min(windowWidth, windowHeight);
    createCanvas(size, size, WEBGL);
    angleMode(DEGREES);

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
    this.bodyPose.detectStart(this.video, (poses) => {
      //   TODO could choose pose with highest confidence
      this.pose = poses[0];
    });

    this.faceMesh.detectStart(this.video, (faces) => {
      //   TODO could choose face with highest confidence
      this.face = faces[0];
      // console.log(this.face);
    });

    // Get the skeleton connection information
    this.connections = this.bodyPose.getSkeleton();

    this.CONFIDENCE_THRESHOLD = 0.1;

    this.audio_context = new AudioContext();
  }

  create_oscillator() {
    this.oscillator = this.audio_context.createOscillator();
    this.oscillator.type = "sine";
    this.oscillator.frequency.value = 1000;
    this.oscillator.connect(this.audio_context.destination);
  }

  draw() {
    scale(height / 2);
    orbitControl();
    background(10, 0, 20);

    // this.head_detection();
    // this.lean_detection();
    this.eye_detection();
    this.drawSkeleton();

    const dims = `video: ${this.video.width}x${this.video.height}\ncanvas: ${width}x${height}\nWindow: ${windowWidth}x${windowHeight}`;
    // this.infoElement.html(dims);
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
        //   console.log(pointA.x, pointA.y, pointB.x, pointB.y);
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
        box(0.06);
        pop();
      }
    }

    // Draw a ground plane
    stroke(255);
    rectMode(CENTER);
    strokeWeight(1);
    fill(255, 100);
    // TODO ground plane transform breaks on panning
    // push();
    translate(0, 1);
    rotateX(PI / 2);
    square(0, 0, 2);
    // pop();
  }

  keypointPos(name) {
    if (!this.pose) {
      return;
    }

    const keypoint_ = this.pose[name];
    if (!keypoint_) {
      return;
    }

    return createVector(
      keypoint_.keypoint3D.x,
      keypoint_.keypoint3D.y,
      keypoint_.keypoint3D.z
    );
  }

  vecToString(vec) {
    return `(${vec.x.toFixed(2)}, ${vec.y.toFixed(2)}, ${vec.z.toFixed(2)})`;
  }

  floatToBytes(n) {
    const array = new Float32Array([n]);
    return new Blob([array.buffer], {
      type: 'application/octet-stream'
    });
  }

  longToBytes(n) {
    const array = new BigUint64Array([n]);
    return new Blob([array.buffer], {
      type: 'application/octet-stream'
    });
  }

  head_detection() {
    const nose = this.keypointPos("nose");

    if (!nose) {
      return;
    }
    const heading = nose.mult([1, 1, 0]).heading();

    // message format: float64:timestamp float64:value

    const message = new Blob([new Float64Array([Date.now()]), new Float64Array([heading])], {
      type: 'application/octet-stream'
    });

    fetch("/data", {
      method: "POST",
      headers: {
        "Content-Type": 'application/octet-stream',
      },
      body: message,
    });

    if (!this.min_heading && !this.max_heading) {
      this.min_heading = heading;
      this.max_heading = heading;
    }
    this.min_heading = min(this.min_heading, heading);
    this.max_heading = max(this.max_heading, heading);

    const relative_turn = map(
      heading,
      this.min_heading,
      this.max_heading,
      0,
      1
    );

    let str = `Min: ${this.min_heading.toFixed(
      2
    )} | Max: ${this.max_heading.toFixed(2)} | Cur: ${heading.toFixed(
      2
    )} ${relative_turn.toFixed(2)}`;
    let warning = "";

    // console.log(heading.toFixed(2));

    if (relative_turn > 0.8 || relative_turn < 0.2) {
      warning += "\nLook straight!";
    } else {
      warning += "";
    }

    this.infoElement.html(str);
    this.warningElement.html(warning);
  }

  lean_detection() {
    const left_shoulder = this.keypointPos("left_shoulder");
    const right_shoulder = this.keypointPos("right_shoulder");
    const left_hip = this.keypointPos("left_hip");
    const right_hip = this.keypointPos("right_hip");

    if (!(left_shoulder && right_shoulder && left_hip && right_hip)) {
      return;
    }

    const X = p5.Vector.normalize(right_hip.sub(left_hip));
    const Z = createVector(0, 0, 1);
    const Y = p5.Vector.normalize(Z.cross(X));
    // TODO plot X, Y, Z axes
    // hip can rotate in XY plane, tho its midpoint is fixed
    // but docs say z dirn is toward camera

    const midpoint = p5.Vector.add(left_shoulder, right_shoulder).mult(0.5);
    push();
    translate(midpoint);
    sphere(0.05);
    pop();

    const heading = midpoint.angleBetween(createVector(1, 0, 0));
    // .mult([0, 1, 1])

    console.log(midpoint.dot(Y));

    if (!this.min_heading && !this.max_heading) {
      this.min_heading = heading;
      this.max_heading = heading;
    }
    this.min_heading = min(this.min_heading, heading);
    this.max_heading = max(this.max_heading, heading);

    const relative_turn = map(
      heading,
      this.min_heading,
      this.max_heading,
      0,
      1
    );

    let str = `Min: ${this.min_heading.toFixed(
      2
    )} | Max: ${this.max_heading.toFixed(2)} | Cur: ${heading.toFixed(
      2
    )} ${relative_turn.toFixed(2)}`;
    let warning = "";

    // console.log(heading.toFixed(2));

    if (relative_turn > 0.8 || relative_turn < 0.2) {
      warning += "Sit straight!";
    } else {
      warning += "";
    }

    this.infoElement.html(str);
    this.warningElement.html(warning);
  }

  // TODO docs
  // https://docs.ml5js.org/#/reference/facemesh
  // https://github.com/tensorflow/tfjs-models/tree/master/face-landmarks-detection
  // https://drive.google.com/file/d/1QvwWNfFoweGVjsXF3DXzcrCnz-mx-Lha/preview
  // https://raw.githubusercontent.com/tensorflow/tfjs-models/master/face-landmarks-detection/mesh_map.jpg
  get_eye_vec(index) {
    return createVector(
      this.face.keypoints[index].x,
      this.face.keypoints[index].y,
      this.face.keypoints[index].z
    );
  }

  eye_detection() {
    if (!this.face) {
      return;
    }

    const right_eye_pairs = [
      [398, 382],
      [384, 381],
      [385, 380],
      [386, 374],
      [387, 373],
      [388, 390],
      [466, 249],
    ];

    const left_eye_pairs = [
      [173, 155],
      [157, 154],
      [158, 153],
      [159, 145],
      [160, 144],
      [161, 163],
      [246, 7],
    ];

    // const THRESHOLD

    const centre = this.get_eye_vec(6);

    const eye_dist = p5.Vector.dist(this.get_eye_vec(6), this.get_eye_vec(463));

    const is_eye_closed = (eye_pairs) => {
      // TODO cud use dist sq, etc optimize
      let dist = 0;
      for (const [indexA, indexB] of eye_pairs) {
        const pointA = this.get_eye_vec(indexA).sub(centre).div(400);
        const pointB = this.get_eye_vec(indexB).sub(centre).div(400);
        // TODO does it always predicts all points? confidence?
        dist += p5.Vector.dist(pointA, pointB) / eye_dist;

        stroke(0, 255, 255);
        strokeWeight(4);
        beginShape();
        vertex(pointA);
        vertex(pointB);
        endShape();

        push();
        translate(pointA);
        box(0.01);
        pop();

        push();
        translate(pointB);
        box(0.01);
        pop();
        // console.log(this.vecToString(pointA), this.vecToString(pointB));
      }

      return dist;
    };

    const a = is_eye_closed(left_eye_pairs);
    const b = is_eye_closed(right_eye_pairs);
    // console.log(a.toFixed(4) * 1000, b.toFixed(4) * 1000);
    const EYE_THRESHOLD = 0.0026;

    this.both_closed =
      a.toFixed(4) < EYE_THRESHOLD && b.toFixed(4) < EYE_THRESHOLD;
    // console.log(this.both_closed);

    this.warningElement.html(this.both_closed ? "Eyes closed" : "Eyes open");

    // TODO may come open in the middle, shd be more robust. maybe count ratio of open/closed
    if (this.both_closed && !this.both_closed_prev) {
      this.last_closed_time = Date.now();
    }

    if (
      this.both_closed &&
      this.last_closed_time &&
      Date.now() - this.last_closed_time > 3000 &&
      !this.oscillator
    ) {
      this.create_oscillator();
      this.oscillator.start();
    }

    if (this.oscillator && !this.both_closed && this.both_closed_prev) {
      this.oscillator.stop();
      this.oscillator = null;
    }

    this.both_closed_prev = this.both_closed;

    for (let j = 0; j < this.face.keypoints.length; j++) {
      const keypoint = this.face.keypoints[j];
      fill(0, 255, 0);
      noStroke();
      circle(keypoint.x, keypoint.y, 5);
    }
  }
}
