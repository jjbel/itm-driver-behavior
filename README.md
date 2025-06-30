# ITM Body Pose Warning

This is a web app to detect the body pose of a human occupant of a vehicle, and warn for unsafe positions in real-time. The app runs on a phone mounted in the interior of the car.

### Try it now!: https://jjbel.github.io/ml5-bodypose-example/

https://github.com/user-attachments/assets/cef779b1-1e01-4884-8254-29dcbf54424f

https://github.com/user-attachments/assets/e1dcc616-9ed5-46cd-b503-68abe0f11b84

- [ITM Body Pose Warning](#itm-body-pose-warning)
    - [Try it now!: https://jjbel.github.io/ml5-bodypose-example/](#try-it-now-httpsjjbelgithubioml5-bodypose-example)
  - [Motivation](#motivation)
  - [Our App](#our-app)
    - [Existing studies focussed on mobile driver safety:](#existing-studies-focussed-on-mobile-driver-safety)
  - [App Architecture](#app-architecture)
  - [Benchmarking with OptiTrack](#benchmarking-with-optitrack)
  - [MATLAB Setup](#matlab-setup)
  - [Keypoints and Coordinate Systems](#keypoints-and-coordinate-systems)
    - [BlazePose](#blazepose)
    - [facemesh](#facemesh)
  - [Todo](#todo)
  - [Other Pose Detection Approaches tried](#other-pose-detection-approaches-tried)
    - [1. ARKit](#1-arkit)
    - [2. OpenPose](#2-openpose)
    - [3. ml5.js bodypose](#3-ml5js-bodypose)
    - [Further Reading](#further-reading)
      - [MoveNet:](#movenet)

## Motivation

According to a [survey](https://crashstats.nhtsa.dot.gov/Api/Public/Publication/812506) of vehicle crash causes conducted by the U.S. Department of Transportation, driver error was the critical reason for the crash in 94% of cases. Of these, 41% were recognition errors, such as driver’s inattention, internal and external distractions, and
inadequate surveillance. 7% of driver errors were non-performance errors, for example due to sleep.

The EU has [mandated](https://single-market-economy.ec.europa.eu/news/mandatory-drivers-assistance-systems-expected-help-save-over-25000-lives-2038-2024-07-05_en) driver assistance systems, including drowsiness detection, for all new vehicles from 2024.
However this does not cover motorcycles, which are 25 times more deadly per kilometer traveled than passenger cars. Modern motorcycles have a lack of Advanced driver-assistance system (ADAS).
ADAS systems are also not present in the majority of older vehicles.

An [IEEE report] (https://spectrum.ieee.org/partial-vehicle-autonomy-risk) discusses the risk of partial vehicle autonomy: occupants of cars with ADAS assume mistakenly believe that hands-free driving features can take full responsibility for driving, and take their hands off the wheel.

In India, there are 700,000 to 1 million food delivery workers on platforms like Zomato and Swiggy (according to [moneycontrol](https://www.moneycontrol.com/news/trends/more-than-a-third-of-food-delivery-workers-in-india-are-graduates-finds-survey-11278821.html)). These delivery workers ride 2-wheeler scooters, with an a phone mounted on the dashboard for navigation and tracking orders. They operate under [high-stress conditions](https://www.fortuneindia.com/business-news/racing-against-time-quick-commerce-is-pushing-delivery-riders-to-the-edge-claims-study/121714) (to cater to 15-minute delivery requirements) often throughout the night.

Most vehicle occupants possess a smartphone with a web browser. This presents an opportunity to make driver-assistance systems accessible to a large population. Smartphones from the last decade are equipped with a high-resolution video camera, a Graphics Processing Unit (GPU) for video processing and Machine Learning inference, and a web browser for running cross-platform apps.

## Our App

We present a javascript web app, which can run offline on any device with a web browser. It runs a body pose estimation in realtime to detect and warn for dangerous seating positions such as:

1. falling asleep (eyes closed)
2. face too close to windshield
3. not looking straight ahead
4. knees on dashboard

The app is also intended be used as a general-purpose realtime markerless body-pose estimator. It can run on a phone mounted within a vehicle cabin or on a motorcycle. This replaces previous marker-based body tracking solutions such as OptiTrack (which also require a multi-camera system which is difficult to mount within a vehicle) at the cost of slightly reduced tracking accuracy and latency (see benchmarks [below](#benchmarking-with-optitrack))

The app was developed as part of a project at the [ITM](https://www.itm.uni-stuttgart.de/en/) (Institute of Engineering and Computational Mechanics) at the University of Stuttgart. The app was tested on the ITM Driving Simulator.

### Existing studies focussed on mobile driver safety:

1. Wijnands, J.S., Thompson, J., Nice, K.A. et al. Real-time monitoring of driver drowsiness on mobile platforms using 3D neural networks. Neural Comput & Applic 32, 9731–9743 (2020). https://doi.org/10.1007/s00521-019-04506-0

They developed a Tensorflow-based Android app for realtime drowsiness detection. This was before the release of the BlazePose and facemesh Tensorflow models in 2021.

The app source code was not released. The app would not be able to be run on iOS devices.

## App Architecture

The app is a javascript web app.

It utilises the [BlazePose](https://blog.tensorflow.org/2021/05/high-fidelity-pose-tracking-with-mediapipe-blazepose-and-tfjs.html) and [facemesh](https://blog.tensorflow.org/2020/03/face-and-hand-tracking-in-browser-with-mediapipe-and-tensorflowjs.html) ML models from Google's Tensorflow, for body tracking and face tracking respectively. These models were developed to run in real-time in the browser on a mobile device.

The app can run on any device with a browser which has modern javascript support. This includes Android and iOS mobile phones, as well as windows and linux devices like Raspberry Pi's. Once downloaded, the app runs model inference locally, and hence offline.

The app runs at 10Hz on an Apple iPhone 14 Pro (2022). We are looking to increase performance to the >30fps possible with Tensorflow.

## Benchmarking with OptiTrack

<!-- TODO fix link -->
<!-- ![OptiTrack Motive UI](https://github.com/user-attachments/assets/ed8eee6a-abea-4906-8596-1c47b003b4e1) -->

We test the accuracy of head turn detection by comparing it with OptiTrack - a marker-based 3D tracking system.

1. An occupant sits in the driving simulator. The iPhone is mounted on the dashboard with the occupant in view.
2. The occupant turns their head through half a rotation from left to right, pausing at 0, 30, 60, and 90 degrees on each side.
3. The app records the angle directly. OptiTrack uses markers mounted on a headband to track.

The data is collected and analyzed in MATLAB:

1. The model data is of much lower amplitude than the OptiTrack data. The UI has buttons to set 0 and 90 degrees, and the scaled output fits much better:

| Optitrack Angle | Model Angle |
| --------------- | ----------- |
| 0&deg;          | 5.955&deg;  |
| 30&deg;         | 28.22&deg;  |
| 60&deg;         | 61.80&deg;  |
| 90&deg;         | 87.98&deg;  |

2. The model has a delay in running, hence the model data is shifted behind the OptiTrack data by around 500ms.

## MATLAB Setup

The `matlab/` directory contains various scripts for live data collection and plotting:
`live_capture.m` collects and plots data from OptiTrack and the phone model in realtime.
It connects to OptiTrack via the OptiTrack MATLAB plugin (https://docs.optitrack.com/plugins/optitrack-matlab-plugin) and reads the rigidbody position and rotation of the face.
Phone model data is sent via HTTP to the same webserver hosting the app, which then echoes the data via UDP to MATLAB. This design was chosen because:

1. The app is already hosted by an HTTP server so sending data back to the PC via HTTP is trivial
2. Receiving data in MATLAB is difficult via HTTP, but there is [official UDP support](https://in.mathworks.com/help/instrument/udp-interface.html)

<!-- # Body Tracking

The app uses the following javascript libraries:

1. TensorFlow MoveNet (https://www.tensorflow.org/hub/tutorials/movenet): real-time pose detection
2. ml5.js bodypose (https://docs.ml5js.org/#/reference/bodypose) : which provides a simple API to actually use MoveNet in javascript
3. p5.js (https://p5js.org/) for graphics functionality like video capture, canvas rendering

The app is hosted on the [Github Pages](https://pages.github.com/) of this repo: https://jjbel.github.io/ml5-bodypose-example/ -->

## Keypoints and Coordinate Systems

### BlazePose

BlazePose estimates 33 keypoints of the entire human body in 3D.

From the [BlazePose blog post](https://blog.tensorflow.org/2021/08/3d-pose-detection-with-mediapipe-blazepose-ghum-tfjs.html):

> `keypoints3D` is an additional array with 33 keypoint objects, each object has x, y, z. The x, y, z are in meter units. The person is modeled as if they were in a 2m x 2m x 2m cubic space. The range for each axis goes from -1 to 1 (therefore 2m total delta). The origin of this 3D space is the hip center (0, 0, 0). From the origin, z is positive if moving closer to the camera, and negative if moving away from the camera.

<details>

<summary>List of keypoints</summary>

```
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

</details>

### facemesh

From the [facemesh blog post](https://blog.tensorflow.org/2020/03/face-and-hand-tracking-in-browser-with-mediapipe-and-tensorflowjs.html) and [model card](https://drive.google.com/file/d/1VFC_wIpw4O7xBOiTgUldl79d9LA-LsnA/view):

[mesh_map.jpg](https://raw.githubusercontent.com/tensorflow/tfjs-models/master/face-landmarks-detection/mesh_map.jpg) : list of facial landmarks with indices.

facemesh outputs 3d coordinates of 468 landmarks.

> x- and y-coordinates follow the image pixel
> coordinates; z-coordinates are relative to the
> face center of mass and are scaled
> proportionally to the face width.

This poses two issues:

1. coordinates are in pixel-space not in real-world meters. So we only have a value proportional to real-world distances
2. The z-coordinate of the face-centroid is zero, which means we cannot use it to estimate depth of the face as a whole, just relative depth of different landmarks.

## Todo

App:
1. increase fps to the >30fps possible with BlazePose
2. figure out why 2 huge delays, one when loading, other before camera feed starts
3. try to select a wide-angle lens of the phone
4. improve UI usability: add a reload button, a button to toggle debug graphics, and more instructions for the user
5. Make the app usable offline after downloading (eg by doing "Add to Home screen" from the browser)

Testing:
1. Test Jonas' MOR model in comparison with actual body movement measured with the app
2. Test more driving scenarios in BeamNG
3. Give a simple pulse to the motion platform to study whiplash

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
