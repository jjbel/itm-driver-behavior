class State {
  preload() {
    // Load the bodyPose model
    console.log("Loading BodyPose model...");
    this.bodyPose = ml5.bodyPose("BlazePose");
    console.log("done");
  }

  setup() {
    // createCanvas(windowWidth, windowHeight);
    createCanvas(1920, 1080);

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

    // video = createCapture(VIDEO);

    // Create the video and hide it
    this.video.hide();

    this.infoElement = select("#info");
    this.warningElement = select("#warning");

    // Start detecting poses in the webcam video
    this.bodyPose.detectStart(this.video, (poses) => {
      //   TODO could choose pose with highest confidence
      this.pose = poses[0];
      //   console.log(poses);
    });

    // Get the skeleton connection information
    this.connections = this.bodyPose.getSkeleton();

    this.CONFIDENCE_THRESHOLD = 0.1;
  }

  draw() {
    // Draw the webcam video
    background(10, 0, 20);
    // scale(-1, 1);
    // image(video, 0, 0);
    image(
      this.video,
      0,
      0,
      width,
      height,
      0,
      0,
      this.video.width,
      this.video.height,
      CONTAIN,
      LEFT,
      TOP
    );

    this.drawSkeleton();

    this.detection();

    const dims = `video: ${this.video.width}x${this.video.height}\ncanvas: ${width}x${height}\nWindow: ${windowWidth}x${windowHeight}`;
    // this.infoElement.html(dims);
  }

  // TODO should implement CONTAIN functionality of image. its not a simple scaling.
  transformX(x) {
    return x;
    return map(x, 0, this.video.width, 0, width);
  }

  transformY(y) {
    return y;
    return map(y, 0, this.video.height, 0, height);
  }

  drawSkeleton() {
    if (!this.pose) {
      return; // No pose detected, nothing to draw
    }

    for (let j = 0; j < this.connections.length; j++) {
      const pointAIndex = this.connections[j][0];
      const pointBIndex = this.connections[j][1];
      const pointA = this.pose.keypoints[pointAIndex];
      const pointB = this.pose.keypoints[pointBIndex];
      // Only draw a line if both points are confident enough
      if (
        pointA.confidence > this.CONFIDENCE_THRESHOLD &&
        pointB.confidence > this.CONFIDENCE_THRESHOLD
      ) {
        stroke(255, 0, 0);
        strokeWeight(2);
        line(
          this.transformX(pointA.x),
          this.transformY(pointA.y),
          this.transformX(pointB.x),
          this.transformY(pointB.y)
        );
        //   console.log(pointA.x, pointA.y, pointB.x, pointB.y);
      }
    }

    // Draw all the tracked landmark points
    for (let j = 0; j < this.pose.keypoints.length; j++) {
      const keypoint = this.pose.keypoints[j];
      if (keypoint.confidence > this.CONFIDENCE_THRESHOLD) {
        fill(0, 255, 0);
        noStroke();
        circle(this.transformX(keypoint.x), this.transformY(keypoint.y), 10);
      }
    }
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

  detection() {
    const left_ear = this.keypointPos("left_eye");
    const right_ear = this.keypointPos("right_eye");
    const nose = this.keypointPos("nose");

    const left_shoulder = this.keypointPos("left_shoulder");
    const right_shoulder = this.keypointPos("right_shoulder");

    if (!(left_ear && right_ear && nose && left_shoulder && right_shoulder)) {
      return;
    }

    // const v = p5.Vector.normalize(
    //   nose.sub(left_ear.add(right_ear).div(2)).mult([1, 1, 0])
    // );
    const v = p5.Vector.normalize(left_ear.sub(right_ear).mult([1, 1, 0]));

    const u = p5.Vector.normalize(
      left_shoulder.sub(right_shoulder).mult([1, 1, 0])
    );

    // console.log(this.vecToString(u), this.vecToString(v));
    // angleMode(DEGREES);
    // const heading = v.heading();
    const heading = u.angleBetween(v);

    if (!this.min_heading && !this.max_heading) {
      this.min_heading = heading;
      this.max_heading = heading;
    }
    this.min_heading = min(this.min_heading, heading);
    this.max_heading = max(this.max_heading, heading);
    const x = map(heading, this.min_heading, this.max_heading, 0, 1);

    let str = `Min: ${this.min_heading.toFixed(
      2
    )} | Max: ${this.max_heading.toFixed(2)} | Cur: ${heading.toFixed(
      2
    )} ${x.toFixed(2)}`;
    let warning = "";

    console.log(heading.toFixed(2));

    if (x > 0.8 || x < 0.2) {
      warning += "\nLook straight!";
    } else {
      warning += "";
    }

    this.infoElement.html(str);
    this.warningElement.html(warning);
  }
}
