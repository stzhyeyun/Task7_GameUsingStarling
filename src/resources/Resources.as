package resources
{
	import flash.display.Bitmap;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	
	import media.Sound;
	
	import starling.events.Event;
	import starling.events.EventDispatcher;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	
	import user.UserInfo;
	import user.UserManager;
	
	public class Resources extends EventDispatcher
	{
		[Embed(
			source = "res/daumSemiBold.ttf",
			fontName = "daumSemiBold",			
			embedAsCFF = "false",
			advancedAntiAliasing = "true")]
		public static const DaumSemiBold:Class;
		
		public static const COMPLETE_LOAD:String = "completeLoad";
		public static const NOTICE_IMAGE:String = "noticeImage";
		public static const USER_PICTURE:String = "userPicture";
		public static const READY_NOTICE_IMAGE:String = "readyNoticeImage";
		public static const READY_USER_PICTURE:String = "readyUserPicture";
		
		private static var _instance:Resources;
		
		private const TAG:String = "[Resources]";
		
		private var _textureAtlasDic:Dictionary;
		private var _soundDic:Dictionary;
		private var _userPictureDic:Dictionary;
		private var _noticeImageDic:Dictionary;
		
		private var _path:File;
		private var _pngList:Array;
		private var _mp3List:Array;
		private var _totalResourcesCount:int;
		
		public static function get instance():Resources
		{
			if (!_instance)
			{
				_instance = new Resources();
			}
			return _instance;
		}

		
		public function Resources()
		{
			
		}
		
		public function dispose():void
		{
			_instance = null;
			
			if (_textureAtlasDic)
			{
				var textureAtlas:TextureAtlas;
				for (var key:Object in _textureAtlasDic)
				{
					textureAtlas = _textureAtlasDic[key];
					if (textureAtlas)
					{
						textureAtlas.dispose();
					}
					textureAtlas = null;
					delete _textureAtlasDic[key];
				}
			}
			_textureAtlasDic = null;
			
			if (_soundDic)
			{
				for (key in _soundDic)
				{
					_soundDic[key] = null;
					delete _soundDic[key];
				}
			}
			_soundDic = null;
			
			if (_userPictureDic)
			{
				var texture:Texture;
				for (key in _userPictureDic)
				{
					texture = _userPictureDic[key];
					if (texture)
					{
						texture.dispose();
					}
					texture = null;
					delete _userPictureDic[key];
				}
			}
			_userPictureDic = null;
			
			if (_noticeImageDic)
			{
				
				for (key in _noticeImageDic)
				{
					texture = _noticeImageDic[key];
					if (texture)
					{
						texture.dispose();
					}
					texture = null;
					delete _noticeImageDic[key];
				}
			}
			_noticeImageDic = null;
		}
		
		/**
		 * 로컬의 해당 경로에서 PNG, XML, MP3 파일을 로드합니다. 
		 * @param path 파일 경로입니다.
		 * Resources.COMPLETE_LOAD 이벤트를 수신하여 로드 완료 시점을 알 수 있습니다.
		 */
		public function loadFromDisk(path:File):void
		{
			if (!path.exists)
			{
				trace(TAG + " load : The path does not exist.");
				return;
			}
			
			_path = path;
			var resourcesList:Array = _path.getDirectoryListing();
			if (!resourcesList)
			{
				trace(TAG + " load : No files.");
				return;
			}
			
			var url:String;
			for (var i:int = 0; i < resourcesList.length; i++)
			{
				url = resourcesList[i].url;
				
				if (url.match(/\.png$/i))
				{
					if (!_pngList)
					{
						_pngList = new Array();
					}
					_pngList.push(url);
					_totalResourcesCount++;
				}
				else if (url.match(/\.xml$/i))
				{
					_totalResourcesCount++;
				}
				else if (url.match(/\.mp3$/i))
				{
					if (!_mp3List)
					{
						_mp3List = new Array();
					}
					_mp3List.push(url);
					_totalResourcesCount++;
				}
			}

			if (_pngList)
			{
				var loader:TextureAtlasLoader;
				var fileName:String;
				for (i = 0; i < _pngList.length; i++)
				{
					url = _pngList[i];
					fileName = url.replace(_path.url + "/", "").replace(/\.png$/i, "");
					
					loader = new TextureAtlasLoader(onLoadedTextureAtlas);
					loader.load(url, fileName);
				}
				_pngList.splice(0, _pngList.length);
				_pngList = null;
				
				loader = null;
				fileName = null;
			}
			
			if (_mp3List)
			{
				var sound:Sound;
				for (i = 0; i < _mp3List.length; i++)
				{
					sound = new Sound();
					sound.addEventListener(flash.events.Event.COMPLETE, onLoadedSound);
					sound.addEventListener(IOErrorEvent.IO_ERROR, onFailedLoadingSound);
					sound.load(new URLRequest(_mp3List[i]));
				}
				_mp3List.splice(0, _mp3List.length);
				_mp3List = null;
				
				sound = null;
			}
		}
		
		/**
		 * 지정된 URL에서 유저의 프로필 사진 또는 공지 이미지를 로드합니다.  
		 * @param type 로드할 콘텐츠의 유형입니다. Resources.USER_PICTURE / Resources.NOTICE_IMAGE 
		 * @param key 유저 ID 또는 공지 이미지의 파일명입니다.
		 * Resources.READY_USER_PICTURE 또는 Resources.READY_NOTICE_IMAGE 이벤트를 수신하여 로드 완료 시점을 알 수 있습니다.
		 */
		public function loadFromURL(type:String, key:String):void
		{
			if (!type || !key)
			{
				if (!type) trace(TAG + " loadFromURL : No type.");
				if (!key) trace(TAG + " loadFromURL : No key.");
				return;
			}
			
			// 로드한 적이 있는 유저 프로필 사진일 경우
			if (type == USER_PICTURE && _userPictureDic && _userPictureDic[key])
			{
				// 로드 완료 이벤트 dispatch
				this.dispatchEvent(
						new starling.events.Event(Resources.READY_USER_PICTURE, false, key));
				return;
			}
			
			var loader:URLBitmapLoader = new URLBitmapLoader(onLoadedFromURL);
			loader.load(type, key);
		}
		
		/**
		 * Texture를 가져옵니다. 
		 * @param textureAtlasName Texture가 속하는 TextureAtlas의 이름입니다.
		 * @param textureName 얻고자 하는 Texture의 이름입니다.
		 * @return 해당 이름의 Texture를 반환합니다. 없을 경우 null을 반환합니다.
		 * 
		 */
		public function getTexture(textureAtlasName:String, textureName:String):Texture
		{
			if (!_textureAtlasDic || !_textureAtlasDic[textureAtlasName])
			{
				if (!_textureAtlasDic) trace(TAG + " getTexture : No texture atlas.");
				if (!_textureAtlasDic[textureAtlasName]) trace(TAG + " getTexture : Not registered texture atlas name.");
				return null;
			}
			
			var texture:Texture = _textureAtlasDic[textureAtlasName].getTexture(textureName);
			
			if (!texture)
			{
				trace(TAG + " getTexture : Not registered texture name.");
			}
			return texture;
		}
		
		/**
		 * Sound를 가져옵니다. 
		 * @param name 얻고자 하는 Sound의 이름입니다.
		 * @return 해당 이름의 Sound를 반환합니다. 없을 경우 null을 반환합니다.
		 * 
		 */
		public function getSound(name:String):Sound
		{
			if (!_soundDic || !_soundDic[name])
			{
				if (!_soundDic) trace(TAG + " getSound : No sounds.");
				if (!_soundDic[name]) trace(TAG + " getSound : Not registered sound name.");
				return null;
			}
			
			return _soundDic[name];
		}
		
		/**
		 * 공지 이미지를 가져옵니다. 
		 * @param name 얻고자 하는 공지 이미지의 이름입니다.
		 * @return 해당 이름의 공지 이미지(Texture)를 반환합니다. 없을 경우 null을 반환합니다.
		 * 
		 */
		public function getNoticeImage(name:String):Texture
		{
			if (name && _noticeImageDic[name])
			{
				return _noticeImageDic[name];
			}
			else
			{
				return null;
			}
		}
		
		/**
		 * 해당 기기에서 로그인 상태인 유저의 프로필 사진을 가져옵니다. 
		 * @return 유저의 프로필 사진(Texture)을 반환합니다. 없을 경우 null을 반환합니다.
		 * 
		 */
		public function getCurrentUserPicture():Texture
		{
			var userInfo:UserInfo = UserManager.instance.userInfo;
			var userId:String = null;
			if (userInfo)
			{
				userId = UserManager.instance.userInfo.userId;
			}
			
			if (userId && _userPictureDic && _userPictureDic[userId])
			{
				return _userPictureDic[userId];
			}
			else
			{
				return null;
			}
		}
		
		/**
		 * 지정한 ID를 가진 유저의 프로필 사진을 가져옵니다. 
		 * @param userId 프로필 사진을 얻고자 하는 유저의 ID입니다.
		 * @return 해당 ID를 가진 유저의 프로질 사진(Texture)입니다. 없을 경우 null을 반환합니다.
		 * 
		 */
		public function getUserPicture(userId:String):Texture
		{
			if (userId && _userPictureDic[userId])
			{
				return _userPictureDic[userId];
			}
			else
			{
				return null;
			}
		}
		
		/**
		 * Resources에서 공지 이미지를 제거합니다. 
		 * 
		 */
		public function removeNoticeImage():void
		{
			if (_noticeImageDic)
			{
				var texture:Texture;
				for (var key:Object in _noticeImageDic)
				{
					texture = _noticeImageDic[key];
					if (texture)
					{
						texture.dispose();
					}
					texture = null;
					delete _noticeImageDic[key];
				}
			}
			_noticeImageDic = null;
		}
		
		private function checkLoadingProgress():void
		{
			if (_totalResourcesCount == 0)
			{
				_path = null;
				
				this.dispatchEvent(new starling.events.Event(Resources.COMPLETE_LOAD));
			}
		}
		
		private function onLoadedTextureAtlas(name:String, bitmap:Bitmap, xml:XML, loader:TextureAtlasLoader):void
		{
			if (!_textureAtlasDic)
			{
				_textureAtlasDic = new Dictionary();
			}
			_textureAtlasDic[name] = new TextureAtlas(Texture.fromBitmap(bitmap), xml);
			
			loader.dispose();
			
			_totalResourcesCount -= 2;
			checkLoadingProgress();
		}
		
		private function onLoadedSound(event:flash.events.Event):void
		{
			var sound:Sound = event.currentTarget as Sound;
			if (!sound)
			{
				trace(TAG + " onLoadedSound : No sound.");
				return;
			}
			
			sound.removeEventListener(flash.events.Event.COMPLETE, onLoadedSound);
			sound.removeEventListener(IOErrorEvent.IO_ERROR, onFailedLoadingSound);
			
			var fileName:String = sound.url.replace(_path.url + "/", "").replace(/\.mp3$/i, "");			
			
			if (!_soundDic)
			{
				_soundDic = new Dictionary();
			}
			_soundDic[fileName] = sound;
			
			_totalResourcesCount--;
			checkLoadingProgress();
		}
				
		private function onFailedLoadingSound(event:IOErrorEvent):void
		{
			event.currentTarget.removeEventListener(flash.events.Event.COMPLETE, onLoadedSound);
			event.currentTarget.removeEventListener(IOErrorEvent.IO_ERROR, onFailedLoadingSound);
			
			trace(TAG + " Failed to load sound.");
			
			_totalResourcesCount--;
			checkLoadingProgress();
		}

		private function onLoadedFromURL(type:String, key:String, bitmap:Bitmap, loader:URLBitmapLoader):void
		{
			switch (type)
			{
				case NOTICE_IMAGE:
				{
					if (!_noticeImageDic)
					{
						_noticeImageDic = new Dictionary();
					}
					_noticeImageDic[key] = Texture.fromBitmap(bitmap);
					
					this.dispatchEvent(
						new starling.events.Event(Resources.READY_NOTICE_IMAGE, false, key));
				}
					break;
				
				case USER_PICTURE:
				{
					if (!_userPictureDic)
					{
						_userPictureDic = new Dictionary();
					}
					_userPictureDic[key] = Texture.fromBitmap(bitmap);
					
					this.dispatchEvent(
						new starling.events.Event(Resources.READY_USER_PICTURE, false, key));
				}
					break;
				
				default:
					return;
			}
			
			loader.dispose();
		}
	}
}