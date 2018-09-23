extends Node

var PriorityQueue = load("res://Scene/PathFinder/PriorityQueue.gd")

class Location:
	var xy
	var z
	func _init(_xy , _z):
		xy = _xy
		z  = _z

class PathFinderNodeFast:
	var F
	var G
	var PX
	var PY
	var Status
	var PZ
	var JumpLength
	func _init():
		F = 0
		G = 0
		PX = 0
		PY = 0
		JumpLength = 0
		PZ = 0
		Status = 0

	func UpdateStatus(newStatus):
		Status = newStatus

var nodes = []
var touchedLocations = []
var mOpen
var mPath = []


var mGridY
var mGridX

var mGrid
var mDirection = [[0,-1], [1,0], [0,1], [-1,0], [1,-1], [1,1], [-1,1], [-1,-1]]
var mOpenNodeValue      = 1
var mCloseNodeValue    	= 2

func init(grid,w,h):
	mGrid = grid
	mGridY = h
	mGridX = w
	
	nodes.resize(mGridX*mGridY)
	mOpen = PriorityQueue.new(nodes)
		
func FindPath(start, end, characterWidth, characterHeight, maxCharacterJumpHeight):
#	while touchedLocations.size() > 0:
#		nodes[touchedLocations.pop_back()] = []
	#init  data
	for i in range(mGridX * mGridY):
		nodes[i]=[]
		
	if mGrid[end.y][end.x] == 0:
		return null
	
	mOpen.Clear()
	
	#init variables
	var mFound              = false
	var mStop               = false
	var mStopped            = false
	var mCloseNodeCounter   = 0
	mOpenNodeValue      	+= 1
	mCloseNodeValue    		+= 2
	var mHEstimate		    = 2
	var mLocationX			= 0
	var mLocationY			= 0
	var mSearchLimit        = 2000
	var mNewLocationX       = 0
	var mNewLocationY       = 0
	var mNewLocation		= 0
	var mNewG				= 0
	var mH					= 0

	var mLocation = Location.new(start.y * mGridX + start.x , 0)
	var mEndLocation = end.y * mGridX + end.x

	var firstNode = PathFinderNodeFast.new()
	firstNode.G = 0
	firstNode.F = mHEstimate
	firstNode.PX = start.x
	firstNode.PY = start.y
	firstNode.PZ = 0
	firstNode.Status = mOpenNodeValue

	if mGrid[start.y + 1][start.x] == 0:
		firstNode.JumpLength = 0
	else:
		firstNode.JumpLength = maxCharacterJumpHeight * 2

	nodes[mLocation.xy].append(firstNode)
	mOpen.Push(mLocation)
	
	while mOpen.Count() > 0 && !mStop:
		mLocation = mOpen.Pop()
		if nodes[mLocation.xy][mLocation.z].Status == mCloseNodeValue:
			continue

		mLocationX = int(mLocation.xy) % int(mGridX)
		mLocationY = floor(mLocation.xy / mGridX)
		
		if mLocation.xy == mEndLocation:
			nodes[mLocation.xy][mLocation.z].UpdateStatus(mCloseNodeValue)
			mFound = true
			break

		if mCloseNodeCounter > mSearchLimit:
			mStopped = true
			print("Over search limit")
			return null

		for i in range(4):
			#坐标
			mNewLocationX = mLocationX + mDirection[i][0]
			mNewLocationY = mLocationY + mDirection[i][1]
			#索引
			mNewLocation  = mNewLocationY * mGridX + mNewLocationX

			var onGround = false #地上标志
			var atCeiling = false#天花板标志

			if mNewLocationX < 0 or mNewLocationX > mGridX - 1 or mNewLocationY < 0 or mNewLocationY > mGridY - 1:
				continue  
			if mGrid[mNewLocationY][mNewLocationX] == 0: #障碍区直接跳过
				continue

			if mGrid[mNewLocationY + 1][mNewLocationX] == 0:
				onGround = true
			elif mGrid[mNewLocationY - characterHeight][mNewLocationX] == 0:
				atCeiling = true

			var jumpLength = nodes[mLocation.xy][mLocation.z].JumpLength
			var newJumpLength = jumpLength

			if atCeiling:#在天花板
				if mNewLocationX != mLocationX:#不在头顶方向
					newJumpLength = max(maxCharacterJumpHeight * 2 + 1, jumpLength + 1)
				else:                             #头顶
					newJumpLength = max(maxCharacterJumpHeight * 2, jumpLength + 2)

			elif onGround:#在地上
				newJumpLength = 0;
			elif mNewLocationY < mLocationY:
				if jumpLength < 2:
					newJumpLength = 3
				elif int(jumpLength) % 2 == 0:
					newJumpLength = jumpLength + 2
				else:
					newJumpLength = jumpLength + 1
			elif mNewLocationY > mLocationY:
				if int(jumpLength) % 2 == 0:
					newJumpLength = max(maxCharacterJumpHeight * 2, jumpLength + 2)
				else:
					newJumpLength = max(maxCharacterJumpHeight * 2, jumpLength + 1)

			elif !onGround && mNewLocationX != mLocationX:
				newJumpLength = jumpLength + 1

			if jumpLength >= 0 && int(jumpLength) % 2 != 0 && mLocationX != mNewLocationX:
				continue;

			if jumpLength >= maxCharacterJumpHeight * 2 && mNewLocationY < mLocationY:
				continue;

			if newJumpLength >= maxCharacterJumpHeight * 2 + 6 && mNewLocationX != mLocationX && (newJumpLength - (maxCharacterJumpHeight * 2 + 6)) % 8 != 3:
				continue;
			
			var test1 = nodes[mLocation.xy][mLocation.z].G
			var test2 = mGrid[mNewLocationY][mNewLocationX]
			var text3 = newJumpLength / 4
			mNewG = nodes[mLocation.xy][mLocation.z].G + mGrid[mNewLocationY][mNewLocationX] + newJumpLength / 4.0

			if nodes[mNewLocation].size() > 0:
				var lowestJump = 0xffff
				var couldMoveSideways = false
				for j in range(nodes[mNewLocation].size()):
					if nodes[mNewLocation][j].JumpLength < lowestJump:
						lowestJump = nodes[mNewLocation][j].JumpLength

					if int(nodes[mNewLocation][j].JumpLength) % 2 == 0 && nodes[mNewLocation][j].JumpLength < maxCharacterJumpHeight * 2 + 6:
						couldMoveSideways = true

				if lowestJump <= newJumpLength && (int(newJumpLength) % 2 != 0 || newJumpLength >= maxCharacterJumpHeight * 2 + 6 || couldMoveSideways):
					continue
			mH = mHEstimate * (abs(mNewLocationX - end.x) + abs(mNewLocationY - end.y))

			var newNode = PathFinderNodeFast.new()
			newNode.JumpLength = newJumpLength
			newNode.PX = mLocationX
			newNode.PY = mLocationY
			newNode.PZ = mLocation.z
			newNode.G = mNewG
			newNode.F = mNewG + mH
			newNode.Status = mOpenNodeValue
			nodes[mNewLocation].append(newNode)

			var location = Location.new(mNewLocation, nodes[mNewLocation].size() - 1)
			mOpen.Push(location)
			
		nodes[mLocation.xy][mLocation.z].UpdateStatus(mCloseNodeValue)
		mCloseNodeCounter += 1

	if mFound:
		var posX = end.x
		var posY = end.y

		var fPrevNodeTmp = PathFinderNodeFast.new()
		var fNodeTmp = nodes[mEndLocation][0]

		var fNode = end
		var fPrevNode = end

		var loc = fNodeTmp.PY * mGridX + fNodeTmp.PX

		var mPath = []
		while fNode.x != fNodeTmp.PX || fNode.y != fNodeTmp.PY:
			var fNextNodeTmp = nodes[loc][fNodeTmp.PZ]
			if mPath.size() == 0:
				mPath.append(fNode)
			elif fNodeTmp.JumpLength == 0 && fPrevNodeTmp.JumpLength != 0:
				mPath.append(fNode)
			elif fNextNodeTmp.JumpLength != 0 && fNodeTmp.JumpLength == 0:
				mPath.append(fNode)
			elif fNode.y > mPath[mPath.size() - 1].y && fNode.y > fNodeTmp.PY:
				mPath.append(fNode)
			elif mGrid[fNode.y][fNode.x - 1] == 0 || mGrid[fNode.y][fNode.x + 1] == 0:
				if fNode.y != mPath[mPath.size() - 1].y && fNode.x != mPath[mPath.size() - 1].x:
					mPath.append(fNode)
			fPrevNode = fNode
			posX = fNodeTmp.PX
			posY = fNodeTmp.PY
			fPrevNodeTmp = fNodeTmp
			fNodeTmp = fNextNodeTmp
			loc = fNodeTmp.PY * mGridX + fNodeTmp.PX;
			fNode = Vector2(posX, posY)

		return mPath
	return null








