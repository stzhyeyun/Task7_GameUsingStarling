package scene.gameScene
{
	import gamedata.DataManager;
	
	import resources.Resources;
	import resources.TextureAtlasName;
	import resources.TextureName;
	
	import starling.core.Starling;
	import starling.display.Button;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.textures.Texture;
	
	import ui.SpriteNumber;
	import ui.popup.PopupManager;
	import ui.popup.PopupName;
	
	import user.UserManager;
	
	import util.Color;

	public class GameSceneUI extends Sprite
	{
		private const HEADER_HEIGHT_RATIO:Number = 0.1;
		
		private var _userPic:Image;
		private var _bestScore:SpriteNumber;
		private var _currentScore:SpriteNumber;
		
		private var _headerWidth:Number;
		private var _headerHeight:Number;
		
		
		public function GameSceneUI()
		{
			
		}
		
		public override function dispose():void
		{
			DataManager.instance.removeEventListener(DataManager.UPDATE_CURRENT_SCORE, onUpdateCurrentScore);
			Resources.instance.removeEventListener(Resources.READY_USER_PICTURE, onUserPictureReady);
			
			super.dispose();
		}
		
		public function initialize(stageWidth:Number, stageHeight:Number, bestScore:int, currentScore:int):void
		{
			var headerHeight:Number = stageHeight * HEADER_HEIGHT_RATIO;
			
			// User picture
			_userPic = new Image(null);
			if (UserManager.instance.loggedIn)
			{
				var texture:Texture = Resources.instance.getCurrentUserPicture();
				
				if (texture)
				{
					_userPic.texture = texture;
					_userPic.visible = true;
				}
				else
				{
					_userPic.visible = false;
				}
			}
			else
			{
				_userPic.visible = false;
			}
			_userPic.height = headerHeight * 0.8;
			_userPic.width = _userPic.height;
			_userPic.pivotX = _userPic.width / 2;
			_userPic.pivotY = _userPic.height / 2;
			_userPic.x = stageWidth * 0.1;
			_userPic.y = headerHeight / 2;
			addChild(_userPic);
			
			// Pause
			var pauseScale:Number = 0.8;
			var pause:Button = new Button(Resources.instance.getTexture(TextureAtlasName.MAIN, TextureName.BTN_PAUSE));
			pause.height = headerHeight * 0.8;
			pause.width = pause.height;
			pause.pivotX = pause.width / 2;
			pause.pivotY = pause.height / 2;
			pause.x = stageWidth * 0.9;
			pause.y = headerHeight / 2;
			pause.addEventListener(TouchEvent.TOUCH, onEndedPauseButton);
			addChild(pause);
			
			// Score
			setScore(stageWidth, stageHeight, bestScore, currentScore);
			
			DataManager.instance.addEventListener(DataManager.UPDATE_CURRENT_SCORE, onUpdateCurrentScore);
			Resources.instance.addEventListener(Resources.READY_USER_PICTURE, onUserPictureReady);
			UserManager.instance.addEventListener(UserManager.LOG_OUT, onLogOut);
		}
		
		/**
		 * 점수 UI를 세팅합니다.
		 * @param stageWidth GameScene의 너비입니다.
		 * @param stageHeight GameScene의 높이입니다.
		 * @param bestScore 최고 점수입니다.
		 * @param currentScore 현재 점수입니다.
		 * 
		 */
		public function setScore(stageWidth:Number, stageHeight:Number, bestScore:int, currentScore:int):void
		{
			var headerHeight:Number = stageHeight * HEADER_HEIGHT_RATIO;
			
			// Best score
			if (_bestScore)
			{
				removeChild(_bestScore, true);
				_bestScore = null;
			}
			_bestScore = new SpriteNumber(bestScore.toString(), Color.BEST_SCORE);
			var bestScoreScale:Number = headerHeight * 0.25 / _bestScore.height;
			_bestScore.height *= bestScoreScale;
			_bestScore.width *= bestScoreScale; 
			_bestScore.x = stageWidth / 2;
			_bestScore.y = stageHeight * 0.2;
			addChild(_bestScore);
			
			// Current score
			if (_currentScore)
			{
				removeChild(_currentScore, true);
				_currentScore = null;
			}
			_currentScore = new SpriteNumber(currentScore.toString(), Color.CURRENT_SCORE);
			var currentScoreScale:Number = headerHeight * 0.4 / _currentScore.height;
			_currentScore.height *= currentScoreScale;
			_currentScore.width *= currentScoreScale; 
			_currentScore.x = stageWidth / 2;
			_currentScore.y = stageHeight * 0.14;
			addChild(_currentScore);
		}
		
		private function onEndedPauseButton(event:TouchEvent):void
		{
			var touch:Touch = event.getTouch(this, TouchPhase.ENDED);
			
			if (!touch)
			{
				return;
			}
			
			// 일시정지 팝업 표시
			PopupManager.instance.showPopup(this, PopupName.PAUSE);
		}
		
		private function onUpdateCurrentScore(event:Event):void
		{
			// 현재 점수 UI 업데이트
			_currentScore.update(String(event.data));
		}
		
		private function onUserPictureReady(event:Event):void
		{
			// 유저 로그인 시 프로필 사진 설정
			var eventTargetId:String = event.data as String;
			var userId:String = UserManager.instance.userInfo.userId;
			
			if (eventTargetId && userId && eventTargetId == userId)
			{
				var headerHeight:Number = Starling.current.nativeStage.stageHeight * HEADER_HEIGHT_RATIO;
				_userPic.texture = Resources.instance.getCurrentUserPicture();
				_userPic.height = headerHeight * 0.8;
				_userPic.width = _userPic.height;
				_userPic.pivotX = _userPic.width / 2;
				_userPic.pivotY = _userPic.height / 2;
				_userPic.x = Starling.current.nativeStage.stageWidth * 0.1;
				_userPic.y = headerHeight / 2;
				_userPic.visible = true;
			}
		}
		
		private function onLogOut(event:Event):void
		{
//			_userPic.texture = Resources.instance.getTexture(TextureAtlasName.MAIN, TextureName.IMG_ANONYMOUS);
			_userPic.visible = false;
		}
	}
}
