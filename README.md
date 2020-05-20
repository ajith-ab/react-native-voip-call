
# react-native-voip-call

## Getting started

`$ npm install react-native-voip-call --save`

### Mostly automatic installation

`$ react-native link react-native-voip-call`

### Manual installation


#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `react-native-voip-call` and add `RNVoipCall.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libRNVoipCall.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)<

#### Android

1. Open up `android/app/src/main/java/[...]/MainActivity.java`
  - Add `import com.ajith.voipcall.RNVoipCallPackage;` to the imports at the top of the file
  - Add `new RNVoipCallPackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
  	```
  	include ':react-native-voip-call'
  	project(':react-native-voip-call').projectDir = new File(rootProject.projectDir, 	'../node_modules/react-native-voip-call/android')
  	```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
  	```
      compile project(':react-native-voip-call')
  	```

#### Windows
[Read it! :D](https://github.com/ReactWindows/react-native)

1. In Visual Studio add the `RNVoipCall.sln` in `node_modules/react-native-voip-call/windows/RNVoipCall.sln` folder to their solution, reference from their app.
2. Open up your `MainPage.cs` app
  - Add `using Voip.Call.RNVoipCall;` to the usings at the top of the file
  - Add `new RNVoipCallPackage()` to the `List<IReactPackage>` returned by the `Packages` method


## Usage
```javascript
import RNVoipCall from 'react-native-voip-call';

// TODO: What to do with the module?
RNVoipCall;
```
  