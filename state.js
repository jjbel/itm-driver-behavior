class State {
  constructor() {
    // this.poses = [];
  }

  preload() {
    // Load the bodyPose model
    console.log("Loading BodyPose model...");
    this.bodyPose = ml5.bodyPose();
    console.log("done");
  }

  setup() {
    createCanvas(windowWidth, windowHeight);

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

    // Start detecting poses in the webcam video
    this.bodyPose.detectStart(this.video, (poses) => {
      this.poses = poses;
    });

    // Get the skeleton connection information
    this.connections = this.bodyPose.getSkeleton();

    this.CONFIDENCE_THRESHOLD = 0.01;
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

    const dims = `video: ${this.video.width}x${this.video.height}\ncanvas: ${width}x${height}\nWindow: ${windowWidth}x${windowHeight}`;
    this.infoElement.html(dims);
  }

  // TODO should implement CONTAIN functionality of image. its not a simple scaling.
  transformX(x) {
    return map(x, 0, this.video.width, 0, width);
  }

  transformY(y) {
    return map(y, 0, this.video.height, 0, height);
  }

  drawSkeleton() {
    if (!this.poses) {
      return; // No poses detected, nothing to draw
    }

    for (const pose of this.poses) {
      for (let j = 0; j < this.connections.length; j++) {
        let pointAIndex = this.connections[j][0];
        let pointBIndex = this.connections[j][1];
        let pointA = pose.keypoints[pointAIndex];
        let pointB = pose.keypoints[pointBIndex];
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
    }

    // Draw all the tracked landmark points
    for (const pose of this.poses) {
      for (let j = 0; j < pose.keypoints.length; j++) {
        let keypoint = pose.keypoints[j];
        if (keypoint.confidence > this.CONFIDENCE_THRESHOLD) {
          fill(0, 255, 0);
          noStroke();
          circle(this.transformX(keypoint.x), this.transformY(keypoint.y), 10);
        }
      }
    }
  }
}
