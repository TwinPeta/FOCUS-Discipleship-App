export type Institution = { id: string; name: string; type: "university" | "high_school"; country?: string };

export type Profile = {
  id: string;
  full_name: string;
  username: string;
  photo_url: string | null;
  email: string | null;
  phone: string | null;
  institution: Institution | null;
  minor_status: string;
  platform_role: string;
};

export type UserRef = { id: string; full_name: string; username: string; photo_url: string | null; community_role?: string | null };

export type CommunitySummary = {
  id: string;
  type: "general" | "specific";
  name: string;
  initials: string;
  institution: Institution | null;
  super_mentor: UserRef | null;
};

export type MyCommunity = {
  community: CommunitySummary;
  membership_status: "member" | "pending";
  joined_at: string | null;
} | null;

export type MyCommunities = { general: MyCommunity; specific: MyCommunity };

export type Post = {
  id: string;
  author: UserRef | null;
  text: string;
  pinned: boolean;
  like_count: number;
  comment_count: number;
  created_at: string;
};

export type Notification = { id: string; title: string; body: string | null; read_at: string | null; created_at: string };

export type PathwaySummary = {
  id: string;
  title: string;
  steps_total: number;
  steps_completed: number;
  status: "completed" | "in_progress" | "locked" | "available";
};

export type Session = { access_token: string; refresh_token: string; user: Profile };
