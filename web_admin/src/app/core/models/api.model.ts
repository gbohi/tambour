export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
  status_code?: number;
  errors?: Record<string, string[]>;
}

export interface PaginatedResponse<T> {
  count: number;
  next: string | null;
  previous: string | null;
  results: T[];
}

export type PageParams = Record<string, string | number | undefined>;
