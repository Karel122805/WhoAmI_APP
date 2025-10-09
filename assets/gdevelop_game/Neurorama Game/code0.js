gdjs.MenuCode = {};
gdjs.MenuCode.localVariables = [];
gdjs.MenuCode.GDNewSpriteObjects1= [];
gdjs.MenuCode.GDNewSpriteObjects2= [];
gdjs.MenuCode.GDEncabezadoObjects1= [];
gdjs.MenuCode.GDEncabezadoObjects2= [];
gdjs.MenuCode.GDNeuroramaObjects1= [];
gdjs.MenuCode.GDNeuroramaObjects2= [];


gdjs.MenuCode.mapOfGDgdjs_9546MenuCode_9546GDNewSpriteObjects1Objects = Hashtable.newFrom({"NewSprite": gdjs.MenuCode.GDNewSpriteObjects1});
gdjs.MenuCode.eventsList0 = function(runtimeScene) {

{


let isConditionTrue_0 = false;
isConditionTrue_0 = false;
isConditionTrue_0 = gdjs.evtTools.runtimeScene.sceneJustBegins(runtimeScene);
if (isConditionTrue_0) {
{gdjs.evtTools.input.touchSimulateMouse(runtimeScene, false);
}
{gdjs.evtTools.runtimeScene.resetTimer(runtimeScene, "boton");
}
}

}


{

gdjs.copyArray(runtimeScene.getObjects("NewSprite"), gdjs.MenuCode.GDNewSpriteObjects1);

let isConditionTrue_0 = false;
isConditionTrue_0 = false;
isConditionTrue_0 = gdjs.evtTools.input.cursorOnObject(gdjs.MenuCode.mapOfGDgdjs_9546MenuCode_9546GDNewSpriteObjects1Objects, runtimeScene, true, false);
if (isConditionTrue_0) {
isConditionTrue_0 = false;
isConditionTrue_0 = gdjs.evtTools.runtimeScene.getTimerElapsedTimeInSecondsOrNaN(runtimeScene, "boton") >= 0.5;
}
if (isConditionTrue_0) {
{gdjs.evtTools.runtimeScene.replaceScene(runtimeScene, "Game", false);
}
}

}


};

gdjs.MenuCode.func = function(runtimeScene) {
runtimeScene.getOnceTriggers().startNewFrame();

gdjs.MenuCode.GDNewSpriteObjects1.length = 0;
gdjs.MenuCode.GDNewSpriteObjects2.length = 0;
gdjs.MenuCode.GDEncabezadoObjects1.length = 0;
gdjs.MenuCode.GDEncabezadoObjects2.length = 0;
gdjs.MenuCode.GDNeuroramaObjects1.length = 0;
gdjs.MenuCode.GDNeuroramaObjects2.length = 0;

gdjs.MenuCode.eventsList0(runtimeScene);
gdjs.MenuCode.GDNewSpriteObjects1.length = 0;
gdjs.MenuCode.GDNewSpriteObjects2.length = 0;
gdjs.MenuCode.GDEncabezadoObjects1.length = 0;
gdjs.MenuCode.GDEncabezadoObjects2.length = 0;
gdjs.MenuCode.GDNeuroramaObjects1.length = 0;
gdjs.MenuCode.GDNeuroramaObjects2.length = 0;


return;

}

gdjs['MenuCode'] = gdjs.MenuCode;
