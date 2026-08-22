use serde::Serialize;

#[derive(Debug, Serialize)]
pub struct ApiResponse<T>
where
    T: Serialize,
{
    pub success: bool,
    pub data: T,
}

impl<T> ApiResponse<T>
where
    T: Serialize,
{
    pub fn ok(data: T) -> Self {
        Self {
            success: true,
            data,
        }
    }
}

#[derive(Debug, Serialize)]
pub struct PaginatedResponse<T>
where
    T: Serialize,
{
    pub items: Vec<T>,
    pub page: u32,
    pub page_size: u32,
    pub total: u64,
}

impl<T> PaginatedResponse<T>
where
    T: Serialize,
{
    pub fn new(items: Vec<T>, page: u32, page_size: u32, total: u64) -> Self {
        Self {
            items,
            page,
            page_size,
            total,
        }
    }
}
