use aims_database::DbPool;

#[derive(Clone)]
pub struct AppState {
    pub db: DbPool,
    pub jwt_secret: String,
}

impl AppState {
    pub fn new(db: DbPool, jwt_secret: String) -> Self {
        Self { db, jwt_secret }
    }
}
