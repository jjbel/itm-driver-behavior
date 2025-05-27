A web app to detect the body pose of a human occupant of a vehicle, and warn for unsafe positions. The app runs on a phone mounted in the interior of the car.

The app uses the following javascript libraries:
1. TensorFlow MoveNet (https://www.tensorflow.org/hub/tutorials/movenet): real-time pose detection
2. ml5.js bodypose (https://docs.ml5js.org/#/reference/bodypose) : which provides a simple API to actually use MoveNet in javascript
3. p5.js (https://p5js.org/) for graphics functionality like video capture, canvas rendering

The app is hosted on the [Github Pages](https://pages.github.com/) of this repo: https://jjbel.github.io/ml5-bodypose-example/

## Motivation

## Keypoints

### BlazePose

```
BlazePose:
0 nose
1 left_eye_inner
2 left_eye
3 left_eye_outer
4 right_eye_inner
5 right_eye
6 right_eye_outer
7 left_ear
8 right_ear
9 mouth_left
10 mouth_right
11 left_shoulder
12 right_shoulder
13 left_elbow
14 right_elbow
15 left_wrist
16 right_wrist
17 left_pinky
18 right_pinky
19 left_index
20 right_index
21 left_thumb
22 right_thumb
23 left_hip
24 right_hip
25 left_knee
26 right_knee
27 left_ankle
28 right_ankle
29 left_heel
30 right_heel
31 left_foot_index
32 right_foot_index
```

## Todo

1. Integrate a biomechanical model
2. Try to select a wide-angle lens of the phone
3. Make the app usable offline after downloading (eg by doing "Add to Home screen" from the browser)
4. figure out why 2 huge delays, one when loading, other before camera feed starts

---

## Other Pose Detection Approaches tried

### 1. ARKit

We initially tried using iPhone Pro models for possibly more accurate pose detection, as they have a Time-of-Flight LiDAR scanner which gives depth data, along with RGB data from the camera.
We used [ARKit's body tracking](https://developer.apple.com/documentation/arkit/capturing-body-motion-in-3d) via Unity's ARFoundation. However ARKit requires full-body visibility to initialize tracking.
If a standing person sat in the driving simulator, ARKit would lose tracking.

The lack of visibility is a central issue. ARKit uses the default 24mm lens of the iPhone 14 Pro for the RGB data to accompany the depth data from the LiDAR sensor. When mounting the iPhone on the dashboard of the car, the visibility is too poor for detection. The iPhone has a wider 13mm lens, but the ARKit API does not give a choice of lens.

We tested ARFoundation by building the [arfoundation-samples](https://github.com/Unity-Technologies/arfoundation-samples) demo app for the iPhone.
2d tracking on a dashboard-mounted iPhone seemed to detect better than 3d tracking, which just failed.


### 2. OpenPose

https://github.com/CMU-Perceptual-Computing-Lab/openpose

> OpenPose: Real-time multi-person keypoint detection library for body, face, hands, and foot estimation

OpenPose uses just RGB data for detection. It can detect poses from an image, video or live camera feed. It supports detecting multiple humans.

However OpenPose is unsuitable because it does not seem to be built for mobile.

Although OpenPose claims realtime detection, testing it on both a laptop and powerful desktop failed to give realtime results.

We tested 3 videos:
1. `video.avi` which comes as a sample with OpenPose
2. `driving-sim 480p`: a 30Hz 1920x1080 video of a person in the driving simulator, downscaled to 480p for better performance. The video was taken using the ultrawide 13mm lensof the iPhone 14 Pro.
3. `driving-sim 240p`: the same video downscaled to 240p

Testing was conducted on:
1. **Laptop**: A Dell XPS Snapdragon X Elite (ARM) running open-pose cpu. This gave unusable framerates of **0.2Hz**, possible because openpose was running in emulation mode on ARM.
2. **Lab PC**: with an Intel i9-14900KF CPU and NVIDIA RTX 4090 GPU. Even this powerful PC ran openpose-gpu at **17Hz** for a 30Hz video, i.e. half of realtime. The GPU utilisation was not high, but certain CPU cores were 100% utilized suggesting openpose-gpu is still CPU single-thread bound.

### 3. ml5.js bodypose

ml5.js bodypose is attractive because:
1. It provides javascript access to the Tensorflow MoveNet and BlazePose models, meaning it can run in a website on any device with a browser
2. The models provide 3d pose detection without the need for a depth camera.
3. The models run in realtime on modern phone hardware
4. The API is relatively simple to use

### Further Reading

#### MoveNet:

1. TensorFlow Blog Post:
https://blog.tensorflow.org/2021/05/next-generation-pose-detection-with-movenet-and-tensorflowjs.html

2. Daniel Shiffman (ml5.js contributor): [DE
Pose Estimation with ml5.js](https://youtu.be/T99fNXTUUaQ) , [3D Pose Estimation with ml5.js](https://youtu.be/IF414I26_K8)


