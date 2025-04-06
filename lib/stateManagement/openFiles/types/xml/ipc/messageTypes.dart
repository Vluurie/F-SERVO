
class MessageType {
  final int type;

  const MessageType(this.type);

  static const Set<int> types = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11};
}

class CheckMessages {
  static const MessageType isInSameRoom = MessageType(11);
}

class PlayerMessages {
  static const MessageType getPosition = MessageType(1);
  static const MessageType setPosition = MessageType(2);
}

class LayoutMessages {
  static const MessageType setPosition = MessageType(3);
  static const MessageType setRotation = MessageType(4);
  static const MessageType setScale = MessageType(5);
  static const MessageType setObjId = MessageType(6);
  static const MessageType setType = MessageType(7);
  static const MessageType setFlag = MessageType(8);
  static const MessageType setRtn = MessageType(9);
  static const MessageType checkExistOrCreate = MessageType(10);
}
