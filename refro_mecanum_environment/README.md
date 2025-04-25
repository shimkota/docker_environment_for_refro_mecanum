# refro_mecanum向け環境構築
## 環境
- Ubuntu 22.04.5 (LTS)

## WSL2でUbuntuをインストール済みなら下記は不要
0. WSLの有効化
1. PowerShellを管理者として実行:スタートメニューを右クリックして「Windows PowerShell(管理者)」を選択
2. 以下のコマンドを入力して、WSLのインストール完了後に、Windowsを再起動
    ```
    wsl --install
    ```
3. Ubuntu 22.04のインストール. コマンドラインからUbuntu をインストールするために以下のコマンドを実行
   ```
    wsl --install -d Ubuntu-20.04
   ```
WSL2にUbuntuがインストールされるので、この後の作業は下記インストラクションによる
```
xxxuser@K000XXXXXX:~$ uname -ra
Linux K000XXXXXX 5.15.90.1-microsoft-standard-WSL2 #1 SMP Fri Jan 27 02:56:13 UTC 2023 x86_64 x86_64 x86_64 GNU/Linux
```

---
## WSL上の作業
- `docker`フォルダ直下に`kjm_ws`フォルダを作成
  ```
  mkdir kjm_ws
  cd ..
  ```
- Docker インストール
   ```
    bash install_docker.sh
   ```
- wslを一度シャットダウンして再起動
   ```
   wsl --shutdown
   ```
- ROS2環境のDocker イメージをビルド
  ```
  bash build.sh
  ```
- コンテナを起動
  ```
  bash start_env.sh
  ```
※dockerコンテナのパスワードはusernameと同じ

---
## Dockerコンテナ内での作業
### Private packege のインストール
- ディレクトリの作成
  ```
  mkdir -p ~/ros2_ws/src/
  ```
- refro_mecanumのインストール
  ```
  cd ~/ros2_ws/src
  git clone https://github.com/tokiryota/refro_mecanum.git -b develop
  ```
### デバイス
- ロボットのセットアップ
### Livox_SDK2のインストール
- (https://github.com/Livox-SDK/Livox-SDK2)
  ```
  cd
  git clone https://github.com/Livox-SDK/Livox-SDK2.git
  cd Livox-SDK2
  mkdir build
  cd build
  cmake .. && make -j
  sudo make install
  ```
### livox_ros_driver2のインストール
- (https://github.com/Livox-SDK/livox_ros_driver2)
  ```
  cd ~/ros2_ws/src
  git clone https://github.com/Livox-SDK/livox_ros_driver2.git
  cd livox_ros_driver2
  ```
- CMakeList.txtにヘッダーを追加
  ```
  nano ~/CMakeList.txt
  ```
  ```
  set(ROS_EDITION "ROS2")
  set(HUMBLE_ROS "humble")
  #if(NOT CMAKE_BUILD_TYPE)
  #  set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Choose Release or Debug" FORCE)
  #endif()
  ```
  を、追加
- package_ROS2.xml to package.xmlをコピー
  ```
  cd ~/ros2_ws/src/livox_ros_driver2
  cp -f package_ROS2.xml package.xml
  ```
- Set parameter : config/MID360_config.json
  - "ip" : "192.168.1.1XX", : XX: Serial No.
- change parameter
  - launch_ROS2/msg_MID360_launch.py
    ```
    xfer_format   = 1    # 0-Pointcloud2(PointXYZRTL), 1-customized pointcloud format
    ```
- build : `ccb`
### Cyclone DDS
- rosdep
  `rosdep update`
- Check DDS
  ```
  printenv RMW_IMPLEMENTATION
  ```
  ==>`rmw_cyclonedds_cpp`
- Tuning
  - Referrence: (https://docs.ros.org/en/foxy/How-To-Guides/DDS-tuning.html)
  - Set max buffer size - temporary
    ```
    sudo nano /etc/sysctl.d/10-cyclone-max.conf
    ```
    ```
    sudo sysctl -w net.core.rmem_max=2147483647
    ```
  - Set min buffer size
    ```
    cd
    nano ~/dds_config.xml
    ```
    ```
    <?xml version="1.0" encoding="UTF-8" ?>
    <CycloneDDS xmlns="https://cdds.io/config" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="https://cdds.io/config
    https://raw.githubusercontent.com/eclipse-cyclonedds/cyclonedds/master/etc/cyclonedds.xsd">
    <Domain id="any">
        <Internal>
            <MinimumSocketReceiveBufferSize>10MB</MinimumSocketReceiveBufferSize>
        </Internal>
    </Domain>
    </CycloneDDS>
    ```
- ワークスペースの作成
  ```
  mkdir -p ~/workspace
  cd ~/workspace
  mkdir maps pcd waypoints
  ```
- 点群データのconfig fileを作成
  - filepath:~/workspace/pcd/config.yaml
  ```
  height: -0.2
  thickness: 0.4
  pcd_path: "/home/refro/workspace/pcd/GlobalMap.pcd"
  robotmap_path: "/home/refro/workspace/maps" 
  ```
### Make controller: libgazebo_ros_drive.so
- install command
  ```
  cd ~/ros2_ws/src
  git clone https://github.com/mhernando/gz_rosa_control.git
  sudo rosdep init
  rosdep update
  rosdep install --from-paths gz_rosa_control -y --ignore-src
  ```
- Modify: src/gazebo_ros_omni_drive.cpp
  - 226(2 places): change topic from `cmd_vel` to `cmd_vel_out`
- build: `ccb`
- `libgazebo_ros_omni_drive.so` is generated in `~/ros2_ws/install/gz_rosa_controll/lib`
- Example of use in a urdf file:
  ```
    <gazebo>
      <plugin name="mecanum_drive_controller" filename="libgazebo_ros_omni_drive.so">

        <odometry_frame>odom</odometry_frame>
        <robot_base_frame>base_link</robot_base_frame>
        <update_rate>20.0</update_rate>
        <publish_rate>20.0</publish_rate>
        <publish_odom>true</publish_odom>
        <publish_odom_tf>true</publish_odom_tf>
        <publish_wheel_tf>false</publish_wheel_tf>

        <wheel_radius>0.1</wheel_radius>
        <base_length>0.4</base_length>
        <base_width>0.4</base_width>
        <wheel_max_speed> 4.0 </wheel_max_speed>
        <wheel_acceleration> 5.0</wheel_acceleration>
        <max_torque> 30.0</max_torque>
        <front_left_joint>front_left_wheel_joint</front_left_joint>
        <front_right_joint>front_right_wheel_joint</front_right_joint>
        <rear_left_joint>rear_left_wheel_joint</rear_left_joint>
        <rear_right_joint>rear_right_wheel_joint</rear_right_joint>
        <joint_config>1 1 1 1</joint_config> 

      </plugin>
  </gazebo>
  ```
### ロボットモデル
- Path: `~/ros2_ws/src/refro_mecanum/mecanum_utils/models/urdf`
- Main file: `mecanum_robot.urdf.xacro
- Convert from `xacro` to `urdf`
  ```
  ros2 run xacro xacro mecanum_robot.urdf.xacro -o mecanum_robot.urdf
  ```
- Convert from `urdf` to `sdf`
  ```
  gz sdf -p mecanum_robot.urdf > ../sdf/mecanum_robot.sdf
  ```
  - SDF file path: ~/ros2_ws/src/refro_mecanum/mecanum_utils/models/sdf/mecanum_robot.sdf
### ROS Launch
```
ros2 launch mecanum_utils gz_world.launch.py
```
```
ros2 launch mecanum_utils sim.launch.py
```

