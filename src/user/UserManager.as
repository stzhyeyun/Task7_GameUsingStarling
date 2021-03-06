package user
{
	import com.bamkie.FacebookExtension;
	
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import gamedata.Data;
	import gamedata.DatabaseURL;
	
	import item.ItemID;
	
	import resources.Resources;
	
	import starling.events.Event;
	
	import system.Manager;

	public class UserManager extends Manager
	{
		public static const LOG_IN:String = "logIn";
		public static const LOG_OUT:String = "logOut";
		public static const GET_USER_DB:String = "getUserDB";
		public static const SET_ITEM:String = "setItem";
		public static const ADD_ITEM:String = "addItem";
		
		private const TAG:String = "[LoginManager]";	
		
		private static var _instance:UserManager;
		
		private var _numLoad:int;
		private var _path:File;
		
		private var _accessToken:AccessToken;
		private var _userInfo:UserInfo;
		
		private var _loggedIn:Boolean;
		private var _initialized:Boolean;
		private var _facebookExtension:FacebookExtension;

		public static function get instance():UserManager
		{
			if (!_instance)
			{
				_instance = new UserManager();
			}
			return _instance;
		}
		
		public function get userInfo():UserInfo
		{
			return _userInfo;
		}
		
		public function get loggedIn():Boolean
		{
			return _loggedIn;
		}
		
				
		public function UserManager()
		{
			
		}
		
		public override function dispose():void
		{
			export();
			
			_instance = null;
			_accessToken = null;
			_userInfo = null;
			_facebookExtension = null;
		}
		
		public override function initialize():void
		{
			_loggedIn = false;
			_initialized = false;
			
			_numLoad = 2;
			_path = File.applicationStorageDirectory.resolvePath("data");
			
			_accessToken = new AccessToken("accessToken", _path);
			_accessToken.addEventListener(Data.SUCCEEDED_READING, onReadAccessToken);
			_accessToken.addEventListener(Data.FAILED_READING, onFailedReadingAccessToken);
			_accessToken.read();
			
			_userInfo = new UserInfo("userInfo", _path);
			_userInfo.addEventListener(Data.SUCCEEDED_READING, onReadUserInfo);
			_userInfo.addEventListener(Data.FAILED_READING, onFailedReadingUserInfo);
			_userInfo.read();
		}

		public function logIn():void
		{
			if (!_facebookExtension)
			{
				_facebookExtension = new FacebookExtension();
				_facebookExtension.initialize(onGotAccessTokenFromFB, onGotUserInfoFromFB);
			}
			
			var permissions:Array = new Array();
			permissions.push("public_profile");
			
			_facebookExtension.logInWithReadPermissions(permissions);
		}
		
		public function logOut():void
		{
			if (!_facebookExtension)
			{
				_facebookExtension = new FacebookExtension();
				_facebookExtension.initialize(onGotAccessTokenFromFB, onGotUserInfoFromFB);
			}
			
			_facebookExtension.logOut();
			
			_loggedIn = false;
			_accessToken.clean();
			_userInfo.clean();
			
			this.dispatchEvent(new starling.events.Event(LOG_OUT));
		}
		
		/**
		 * 유저의 아이템 데이터를 업데이트합니다. 
		 * @param type UserManager.SET_ITEM, UserManager.ADD_ITEM 
		 * @param itemId 업데이트할 아이템의 ID입니다.
		 * @param numItem 해당 아이템의 변경된 개수입니다.
		 * @param needToUpdateDB true : 로컬 데이터와 DB를 업데이트 / false : 로컬 데이터만 업데이트
		 * 
		 */
		public function updateItemData(type:String, itemId:int, numItem:int, needToUpdateDB:Boolean = false):void
		{
			if (!_userInfo)
			{
				trace(TAG + " updateItemData : No userInfo.");
				return;
			}
			
			switch (type)
			{
				case SET_ITEM:
				{
					_userInfo.setItem(itemId, numItem);
				}
					break;
				
				case ADD_ITEM:
				{
					_userInfo.addItem(itemId, numItem);
				}
					break;
				
				default:
					trace(TAG + " updateItemData : Invalid type.");
					return;
			}
			
			if (needToUpdateDB)
			{
				var url:String =
					DatabaseURL.USER +
					"updateItemData.php" +
					"?userId=" + _userInfo.userId +
					"&itemId=" + itemId +
					"&numItem=" + numItem;
				var loader:URLLoader = new URLLoader(new URLRequest(url));
			}
		}
		
		/**
		 * 유저 정보를 로컬에 저장합니다. 
		 * (로컬에 저장된 유저 정보의 유무로 다시 어플리케이션 실행 시 로그인 여부 판단)
		 */
		public function export():void
		{
			if (_accessToken)
			{
				_accessToken.write();
			}
			
			if (_userInfo)
			{
				_userInfo.write();
			}
		}
		
		private function onReadAccessToken(event:starling.events.Event):void
		{
			_numLoad--;
			checkLoadingProgress();
		}
		
		private function onFailedReadingAccessToken(event:starling.events.Event):void
		{
			_numLoad--;
			checkLoadingProgress();
		}
		
		private function onReadUserInfo(event:starling.events.Event):void
		{
			// 유저 프로필 사진 로드
			Resources.instance.loadFromURL(Resources.USER_PICTURE, _userInfo.userId);
			
			// DB 업데이트
			var url:String =
				DatabaseURL.USER +
				"addUser.php" +
				"?id=" + _userInfo.userId +
				"&name=" + _userInfo.userName +
				"&score=" + _userInfo.score;
			
			var loader:URLLoader = new URLLoader(new URLRequest(url));
			loader.addEventListener(flash.events.Event.COMPLETE, onGotUserInfoFromDB);
			
			_loggedIn = true;
			this.dispatchEvent(new starling.events.Event(UserManager.LOG_IN));
			
			_numLoad--;
			checkLoadingProgress();
		}
		
		private function onFailedReadingUserInfo(event:starling.events.Event):void
		{
			_loggedIn = false;
			this.dispatchEvent(new starling.events.Event(LOG_OUT));
			
			_numLoad--;
			checkLoadingProgress();
		}
		
		private function checkLoadingProgress():void
		{
			if (_numLoad == 0)
			{
				_accessToken.removeEventListener(Data.SUCCEEDED_READING, onReadAccessToken);
				_accessToken.removeEventListener(Data.FAILED_READING, onFailedReadingAccessToken);
				
				_userInfo.removeEventListener(Data.SUCCEEDED_READING, onReadUserInfo);
				_userInfo.removeEventListener(Data.FAILED_READING, onFailedReadingUserInfo);
				
				this.dispatchEvent(new starling.events.Event(Manager.INITIALIZED));
			}
		}
		
		private function onGotAccessTokenFromFB(tokenData:String):void
		{
			_accessToken.setData(tokenData);
			_accessToken.write();
		}
		
		private function onGotUserInfoFromFB(info:String):void
		{
			// 로컬 유저 정보 세팅
			_userInfo.setData(info);
			
			// 유저 프로필 사진 로드
			Resources.instance.loadFromURL(Resources.USER_PICTURE, _userInfo.userId);
			
			// DB 업데이트
			var url:String =
				DatabaseURL.USER +
				"addUser.php" +
				"?id=" + _userInfo.userId +
				"&name=" + _userInfo.userName +
				"&score=" + _userInfo.score;
			
			var loader:URLLoader = new URLLoader(new URLRequest(url));
			loader.addEventListener(flash.events.Event.COMPLETE, onGotUserInfoFromDB);
			
			_loggedIn = true;
			this.dispatchEvent(new starling.events.Event(LOG_IN));
		}
		
		private function onGotUserInfoFromDB(event:flash.events.Event):void
		{
			var urlLoader:URLLoader = event.currentTarget as URLLoader;
			urlLoader.removeEventListener(flash.events.Event.COMPLETE, onGotUserInfoFromDB);
			
			// 로컬 유저 정보 업데이트
			if (urlLoader.data != "[]")
			{
				var data:Object = JSON.parse(urlLoader.data);
				
				_userInfo.score = data[0].score;
				_userInfo.addItem(ItemID.REFRESH_BLOCKS, data[0].numItem0);
				_userInfo.addItem(ItemID.UNDO, data[0].numItem1);
				_userInfo.attendance = data[0].attendance;
				_userInfo.rewarded = (data[0].rewarded == 1)? true : false;
				
				this.dispatchEvent(new starling.events.Event(GET_USER_DB));
			}
		}
	}
}