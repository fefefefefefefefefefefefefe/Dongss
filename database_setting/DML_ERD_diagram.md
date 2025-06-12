Table user {
  id integer [primary key, increment]
  username varchar [unique, not null]
  password varchar [not null]
  email varchar [unique, not null]
  nickname varchar [unique]
  status varchar [note: "ENUM('active', 'inactive', 'suspended', 'deleted'), default: 'active'"]
  created_at datetime [note: "default: current_timestamp"]
}

Table user_profile {
  user_id integer [primary key, ref: > user.id]
  name varchar [not null]
  profile_img varchar
  bio text
  gender varchar
  website varchar
  location varchar
  birthday date
}

Table user_oauth {
  user_id integer [primary key, ref: > user.id]
  oauth_provider varchar
  oauth_id varchar
}

Table user_security {
  user_id integer [primary key, ref: > user.id]
  email_verified boolean [note: "default: false"]
  last_login_at datetime
}

Table follow {
  follower_id integer [not null, ref: > user.id]
  following_id integer [not null, ref: > user.id]
  created_at datetime [note: "default: current_timestamp"]
  Note: "PRIMARY KEY (follower_id, following_id)"
}

Table community {
  id integer [primary key, increment]
  name varchar [unique, not null]
  description varchar
  admin_id integer [ref: > user.id]
  is_private boolean [note: "default: false"]
  created_at datetime [note: "default: current_timestamp"]
}

Table post {
  id integer [primary key, increment]
  user_id integer [not null, ref: > user.id]
  community_id integer [not null, ref: > community.id]
  title varchar
  content text
  is_anonymous boolean [note: "default: false"]
  visibility varchar [note: "ENUM('public', 'followers', 'private'), default: 'public'"]
  view_count integer [note: "default: 0"]
  comment_count integer [note: "default: 0"]
  is_blinded boolean [note: "default: false"]
  is_deleted boolean [note: "default: false"]
  created_at datetime [note: "default: current_timestamp"]
  updated_at datetime
}

Table post_file {
  id integer [primary key, increment]
  post_id integer [not null, ref: > post.id]
  file_url varchar
  file_type varchar
  is_thumbnail boolean [note: "default: false"]
  uploaded_at datetime [note: "default: current_timestamp"]
}

Table tag {
  id integer [primary key, increment]
  name varchar [unique, not null]
}

Table post_tag {
  post_id integer [not null, ref: > post.id]
  tag_id integer [not null, ref: > tag.id]
  Note: "PRIMARY KEY(post_id, tag_id)"
}

Table comment {
  id integer [primary key, increment]
  post_id integer [not null, ref: > post.id]
  user_id integer [not null, ref: > user.id]
  content text
  parent_id integer [ref: > comment.id]
  is_anonymous boolean [note: "default: false"]
  is_blinded boolean [note: "default: false"]
  is_deleted boolean [note: "default: false"]
  created_at datetime [note: "default: current_timestamp"]
  updated_at datetime
}

Table post_like {
  id integer [primary key, increment]
  post_id integer [not null, ref: > post.id]
  user_id integer [not null, ref: > user.id]
  created_at datetime [note: "default: current_timestamp"]
  Note: "UNIQUE(post_id, user_id)"
}

Table comment_like {
  id integer [primary key, increment]
  comment_id integer [not null, ref: > comment.id]
  user_id integer [not null, ref: > user.id]
  created_at datetime [note: "default: current_timestamp"]
  Note: "UNIQUE(comment_id, user_id)"
}

Table emoji {
  id integer [primary key, increment]
  name varchar [unique, not null]
}

Table post_reaction {
  post_id integer [not null, ref: > post.id]
  user_id integer [not null, ref: > user.id]
  emoji_id integer [not null, ref: > emoji.id]
  created_at datetime [note: "default: current_timestamp"]
  Note: "PRIMARY KEY(post_id, user_id, emoji_id)"
}

Table chat_room {
  id integer [primary key, increment]
  name varchar
  is_group boolean
  created_at datetime [note: "default: current_timestamp"]
}

Table chat_message {
  id integer [primary key, increment]
  chatroom_id integer [not null, ref: > chat_room.id]
  sender_id integer [not null, ref: > user.id]
  message text
  file_url varchar
  is_deleted boolean [note: "default: false"]
  created_at datetime [note: "default: current_timestamp"]
}

Table notification {
  id integer [primary key, increment]
  user_id integer [not null, ref: > user.id]
  type varchar
  message varchar
  is_read boolean [note: "default: false"]
  source_user_id integer [ref: > user.id]
  related_post_id integer [ref: > post.id]
  related_comment_id integer [ref: > comment.id]
  chat_message_id integer [ref: > chat_message.id]
  chat_room_id integer [ref: > chat_room.id]
  created_at datetime [note: "default: current_timestamp"]
}

Table chat_room_user {
  id integer [primary key, increment]
  chatroom_id integer [not null, ref: > chat_room.id]
  user_id integer [not null, ref: > user.id]
  left_at datetime
}

Table report {
  id integer [primary key, increment]
  reporter_id integer [not null, ref: > user.id]
  target_type varchar
  target_id integer [not null]
  reason varchar
  created_at datetime [note: "default: current_timestamp"]
}

Table user_block {
  id integer [primary key, increment]
  user_id integer [not null, ref: > user.id]
  blocked_user_id integer [not null, ref: > user.id]
  created_at datetime [note: "default: current_timestamp"]
  Note: "UNIQUE(user_id, blocked_user_id)"
}

Table profile_visit {
  id integer [primary key, increment]
  visitor_id integer [not null, ref: > user.id]
  profile_user_id integer [not null, ref: > user.id]
  visited_at datetime [note: "default: current_timestamp"]
}

Table search_history {
  id integer [primary key, increment]
  user_id integer [not null, ref: > user.id]
  keyword varchar
  searched_at datetime [note: "default: current_timestamp"]
}

Table feed_cache {
  id integer [primary key, increment]
  user_id integer [not null, ref: > user.id]
  post_id integer [not null, ref: > post.id]
  score float
  created_at datetime [note: "default: current_timestamp"]
}

Table file_report {
  id integer [primary key, increment]
  file_id integer [not null, ref: > post_file.id]
  reporter_id integer [not null, ref: > user.id]
  reason varchar
  created_at datetime [note: "default: current_timestamp"]
}

Ref: "comment"."id" < "comment"."post_id"
