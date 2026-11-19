export type Institution = { id: string; name: string; type: "university" | "institute" | "high_school"; country?: string };

export type Profile = {
  id: string;
  full_name: string;
  username: string;
  photo_url: string | null;
  email: string | null;
  phone: string | null;
  email_verified: boolean;
  phone_verified: boolean;
  country: string;
  institution: Institution | null;
  minor_status: string;
  platform_role: string;
};

export type UserRef = {
  id: string; full_name: string; username: string; photo_url: string | null; community_role?: string | null; online?: boolean;
};

export type Meeting = { weekday?: string; start_time?: string; location?: string } | null;

export type CommunitySummary = {
  id: string;
  type: "general" | "specific";
  name: string;
  initials: string;
  institution: Institution | null;
  super_mentor: UserRef | null;
  meeting: Meeting;
  can_request: boolean;
  membership_status: "member" | "pending" | "none";
};

export type Community = CommunitySummary & {
  description: string; members_count: number; online_count: number; leadership: UserRef[];
};

export type MyCommunity = {
  community: CommunitySummary;
  membership_status: "member" | "pending";
  joined_at: string | null;
  join_request_id: string | null;
} | null;

export type MyCommunities = { general: MyCommunity; specific: MyCommunity };

export type Media = { id: string; kind: "image" | "video"; url: string; thumbnail_url: string | null };

export type Post = {
  id: string; community_id: string; author: UserRef | null; text: string; media: Media[]; pinned: boolean;
  like_count: number; comment_count: number; liked_by_me: boolean; created_at: string;
};

export type Comment = { id: string; author: UserRef | null; text: string; created_at: string; anonymous?: boolean };

export type PrayerRequest = {
  id: string; community_id: string; author: UserRef | null; text: string; prayed_count: number; prayed_by_me: boolean;
  response_count: number; created_at: string;
};

export type Testimony = {
  id: string; community_id: string; format: "video" | "story"; title: string; excerpt: string; body: string | null; media: Media[];
  author: UserRef | null; institution_name: string | null; status: string; approved_by: string | null;
  published_at: string | null; created_at: string | null;
};

export type Resource = {
  id: string; type: "video" | "devotional" | "document" | "quiz"; title: string; category: string | null; tags: string[];
  duration_seconds: number | null; read_minutes: number | null; question_count: number | null; added_by: UserRef | null;
  thumbnail_url: string | null; stream_url: string | null; body_html: string | null; document_url: string | null;
  my_progress: { position_seconds: number; completed: boolean };
};

export type Quiz = {
  id: string; title: string; pass_mark_percent: number;
  questions: { id: string; text: string; options: { id: string; text: string }[] }[];
};

export type MeetingItem = { id: string; community_id: string; starts_at: string; room: string; going: boolean; attended: boolean };

export type Conversation = {
  id: string; participant: UserRef; kind: "mentor" | "member"; last_message: string; last_message_at: string; unread_count: number;
};

export type Message = { id: string; conversation_id: string; sender_id: string; text: string; sent_at: string; read_at: string | null };

export type Notification = {
  id: string; type: string; title: string; body: string | null; target_route: string | null; read_at: string | null; created_at: string;
};

export type PathwaySummary = {
  id: string; title: string; steps_total: number; steps_completed: number; current_step: number | null;
  status: "completed" | "in_progress" | "locked" | "available"; unlock_hint: string | null;
};

export type PathwayStep = {
  id: string; order: number; title: string; type: string; resource_id: string | null; duration_label: string | null;
  status: "done" | "current" | "upcoming";
};

export type PathwayDetail = PathwaySummary & { steps: PathwayStep[] };

export type Badge = { id: string; name: string; icon_url: string | null; earned: boolean; earned_at: string | null };

export type JoinRequest = {
  id: string; community: CommunitySummary; user: UserRef; status: string; created_at: string; note: string | null;
};

export type ModerationCase = {
  id: string; content: string; target_id: string; author: { id: string; full_name: string } | null; preview: string; reason: string;
  report_count: number; first_reporter_name: string; reported_at: string;
};

export type Page<T> = { items: T[]; next_cursor: string | null };

export type Session = { access_token: string; refresh_token: string; user: Profile };
